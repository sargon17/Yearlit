// Lead Delivery Sandcastle Loop — parallel architecture/coding/review/test orchestration
//
// This is a separate flow from .sandcastle/main.mts.
// It reuses the shared planner and merger prompts, but runs each selected task
// through a lead-delivery pipeline:
//   architect → coder → review/coder fixes (max 2) → tester/coder fixes → merge
//
// Usage:
//   bun run sandcastle:lead-delivery
// Or directly:
//   bun .sandcastle/lead-delivery/main.mts

import * as sandcastle from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const MAX_ITERATIONS = 10;
const MAX_REVIEW_ROUNDS = 2;
const MAX_VALIDATION_FIX_ATTEMPTS = 3;

const hooks = {
  sandbox: { onSandboxReady: [{ command: "bun install --frozen-lockfile" }] },
};

const copyToWorktree = ["node_modules"];

// Share host auth with Docker sandboxes. `gh` needs either GH_TOKEN or the
// GitHub CLI config dir; Codex needs ~/.codex from `codex login`.
// @ts-expect-error This repo does not currently install @types/node.
const { existsSync, readFileSync } = await import("node:fs");
// @ts-expect-error This repo does not currently install @types/node.
const { homedir } = await import("node:os");
// @ts-expect-error This repo does not currently install @types/node.
const { execFileSync } = await import("node:child_process");

function readDotenv(path: string): Record<string, string> {
  if (!existsSync(path)) {
    return {};
  }

  return Object.fromEntries(
    readFileSync(path, "utf8")
      .split("\n")
      .map((line: string) => line.trim())
      .filter((line: string) => line.length > 0 && !line.startsWith("#"))
      .map((line: string) => {
        const index = line.indexOf("=");
        if (index === -1) {
          return [line, ""];
        }
        return [line.slice(0, index), line.slice(index + 1).replace(/^['\"]|['\"]$/g, "")];
      }),
  );
}

function readHostGhToken(): string | undefined {
  try {
    return execFileSync("gh", ["auth", "token"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return undefined;
  }
}

const dotenv = readDotenv(".sandcastle/.env");
const ghToken = process.env.GH_TOKEN ?? process.env.GITHUB_TOKEN ?? dotenv.GH_TOKEN ?? dotenv.GITHUB_TOKEN ?? readHostGhToken();
const sandboxEnv = Object.fromEntries(
  [
    ["GH_TOKEN", ghToken],
    ["GITHUB_TOKEN", ghToken],
    ["OPENAI_KEY", process.env.OPENAI_KEY ?? dotenv.OPENAI_KEY],
    ["OPENAI_API_KEY", process.env.OPENAI_API_KEY ?? dotenv.OPENAI_API_KEY],
  ].filter((entry): entry is readonly [string, string] => Boolean(entry[1])),
);

const mounts = [
  {
    hostPath: "~/.codex",
    sandboxPath: "~/.codex",
  },
];

if (existsSync(`${homedir()}/.config/gh`)) {
  mounts.push({
    hostPath: "~/.config/gh",
    sandboxPath: "~/.config/gh",
  });
}

const sandboxProvider = docker({
  mounts,
  env: sandboxEnv,
});

// Branch used by reviewer/tester diffs. Keep this explicit so the loop does
// not need Node child_process/process typings just to discover the current branch.
const BASE_BRANCH = "develop";

type Issue = { id: string; title: string; branch: string };
type ReviewResult = {
  verdict: "pass" | "needs_fixes" | "blocker";
  findings?: unknown[];
  summary?: string;
};
type TestResult = {
  verdict: "pass" | "fail";
  commands?: string[];
  failures?: unknown[];
  summary?: string;
};

type HostValidationResult = {
  ok: boolean;
  command: string;
  stdout: string;
  stderr: string;
  exitCode: number;
};

let hostValidationQueue = Promise.resolve();

async function runHostCommand(
  command: string,
  cwd: string,
): Promise<HostValidationResult> {
  // Sandcastle runs this script with Node/tsx. Use a dynamic import so the
  // Docker flow stays independent from the sandbox runtime and so host-only
  // validation can execute against the checked-out worktree on macOS.
  // @ts-expect-error This repo does not currently install @types/node.
  const { spawn } = await import("node:child_process");

  return await new Promise((resolve) => {
    const child = spawn("/bin/bash", ["-lc", command], {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk: { toString(): string }) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk: { toString(): string }) => {
      stderr += chunk.toString();
    });

    child.on("close", (code: number | null) => {
      const exitCode = code ?? 1;
      resolve({
        ok: exitCode === 0,
        command,
        stdout,
        stderr,
        exitCode,
      });
    });

    child.on("error", (error: Error) => {
      resolve({
        ok: false,
        command,
        stdout,
        stderr: stderr + error.message,
        exitCode: 1,
      });
    });
  });
}

async function runQueuedHostValidation(
  issue: Issue,
  worktreePath: string,
): Promise<HostValidationResult> {
  const command = [
    `if git diff --name-only ${BASE_BRANCH}...HEAD | grep -Eq '\\.(swift|xcodeproj|plist|entitlements|xcconfig)$|Package\\.(swift|resolved)$|project\\.pbxproj$'; then`,
    "  echo 'iOS project changes detected; running host macOS on-device validation.';",
    "  bun run check:swift;",
    "else",
    "  echo 'No iOS build-impacting changes detected; skipping host macOS validation.';",
    "fi",
  ].join("\n");

  const run = async () => {
    console.log(`  → ${issue.id}: waiting for host macOS validation slot`);
    console.log(`  → ${issue.id}: running host validation in ${worktreePath}`);
    const result = await runHostCommand(command, worktreePath);
    if (result.ok) {
      console.log(result.stdout);
      console.log(`  ✓ ${issue.id}: host macOS on-device validation passed`);
    } else {
      console.error(result.stdout);
      console.error(result.stderr);
      console.error(
        `  ✗ ${issue.id}: host macOS on-device validation failed with exit ${result.exitCode}`,
      );
    }
    return result;
  };

  const resultPromise = hostValidationQueue.then(run, run);
  hostValidationQueue = resultPromise.then(
    () => undefined,
    () => undefined,
  );
  return await resultPromise;
}

function parseTaggedJson<T>(stdout: string, tag: string): T {
  const match = stdout.match(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`));
  if (!match) {
    throw new Error(`Agent did not produce a <${tag}> tag.\n\n${stdout}`);
  }
  return JSON.parse(match[1]!);
}

function stringify(value: unknown): string {
  return JSON.stringify(value, null, 2);
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

for (let iteration = 1; iteration <= MAX_ITERATIONS; iteration++) {
  console.log(`\n=== Lead Delivery Iteration ${iteration}/${MAX_ITERATIONS} ===\n`);

  // Phase 1: shared planner selects currently-unblocked issues.
  const plan = await sandcastle.run({
    hooks,
    sandbox: sandboxProvider,
    name: "planner",
    maxIterations: 1,
    agent: sandcastle.codex("gpt-5.5"),
    promptFile: "./.sandcastle/plan-prompt.md",
  });

  const { issues } = parseTaggedJson<{ issues: Issue[] }>(plan.stdout, "plan");

  if (issues.length === 0) {
    console.log("No unblocked issues to work on. Exiting.");
    break;
  }

  console.log(
    `Planning complete. ${issues.length} issue(s) to work in parallel:`,
  );
  for (const issue of issues) {
    console.log(`  ${issue.id}: ${issue.title} → ${issue.branch}`);
  }

  // Phase 2: task pipelines run in parallel; each task gets its own sandbox.
  const settled = await Promise.allSettled(
    issues.map(async (issue) => {
      try {
        const result = await runIssuePipeline(issue);
        return result;
      } catch (error) {
        console.error(
          `  ✗ ${issue.id} (${issue.branch}) failed during pipeline:`,
          error,
        );
        throw error;
      }
    }),
  );

  async function runIssuePipeline(issue: Issue) {
    const sandbox = await sandcastle.createSandbox({
      branch: issue.branch,
      sandbox: sandboxProvider,
      hooks,
      copyToWorktree,
    });

    const allCommits: unknown[] = [];

    try {
        const architectureRun = await sandbox.run({
          name: "architect",
          maxIterations: 1,
          agent: sandcastle.codex("gpt-5.5"),
          promptFile: "./.sandcastle/lead-delivery/architect-prompt.md",
          promptArgs: {
            TASK_ID: issue.id,
            ISSUE_TITLE: issue.title,
            BRANCH: issue.branch,
            BASE_BRANCH,
          },
        });
        allCommits.push(...architectureRun.commits);

        const architecture = parseTaggedJson<unknown>(
          architectureRun.stdout,
          "architecture",
        );

        const implementRun = await sandbox.run({
          name: "coder",
          maxIterations: 100,
          agent: sandcastle.codex("gpt-5.4-mini"),
          promptFile: "./.sandcastle/lead-delivery/coder-prompt.md",
          promptArgs: {
            MODE: "implement",
            TASK_ID: issue.id,
            ISSUE_TITLE: issue.title,
            BRANCH: issue.branch,
            BASE_BRANCH,
            ARCHITECTURE: stringify(architecture),
            FEEDBACK: "",
          },
        });
        allCommits.push(...implementRun.commits);

        for (let round = 1; round <= MAX_REVIEW_ROUNDS; round++) {
          const reviewRun = await sandbox.run({
            name: `reviewer-${round}`,
            maxIterations: 1,
            agent: sandcastle.codex("gpt-5.5"),
            promptFile: "./.sandcastle/lead-delivery/review-prompt.md",
            promptArgs: {
              TASK_ID: issue.id,
              ISSUE_TITLE: issue.title,
              BRANCH: issue.branch,
              BASE_BRANCH,
              ROUND: String(round),
              ARCHITECTURE: stringify(architecture),
            },
          });
          allCommits.push(...reviewRun.commits);

          const review = parseTaggedJson<ReviewResult>(
            reviewRun.stdout,
            "review",
          );

          if (review.verdict === "pass") {
            console.log(`  ✓ ${issue.id}: review passed on round ${round}`);
            break;
          }

          const fixRun = await sandbox.run({
            name: `coder-review-fixes-${round}`,
            maxIterations: 50,
            agent: sandcastle.codex("gpt-5.4-mini"),
            promptFile: "./.sandcastle/lead-delivery/coder-prompt.md",
            promptArgs: {
              MODE: "review-fixes",
              TASK_ID: issue.id,
              ISSUE_TITLE: issue.title,
              BRANCH: issue.branch,
              BASE_BRANCH,
              ARCHITECTURE: stringify(architecture),
              FEEDBACK: stringify(review),
            },
          });
          allCommits.push(...fixRun.commits);
        }

        let testResult: TestResult | undefined;
        let hostValidation: HostValidationResult | undefined;
        for (let attempt = 0; attempt <= MAX_VALIDATION_FIX_ATTEMPTS; attempt++) {
          const testRun = await sandbox.run({
            name: attempt === 0 ? "tester" : `tester-rerun-${attempt}`,
            maxIterations: 1,
            completionSignal: "</test>",
            agent: sandcastle.codex("gpt-5.4-mini"),
            promptFile: "./.sandcastle/lead-delivery/test-prompt.md",
            promptArgs: {
              TASK_ID: issue.id,
              ISSUE_TITLE: issue.title,
              BRANCH: issue.branch,
              BASE_BRANCH,
              ARCHITECTURE: stringify(architecture),
            },
          });
          allCommits.push(...testRun.commits);

          testResult = parseTaggedJson<TestResult>(testRun.stdout, "test");

          if (testResult.verdict === "pass") {
            console.log(`  ✓ ${issue.id}: sandbox validation passed`);
            hostValidation = await runQueuedHostValidation(
              issue,
              sandbox.worktreePath,
            );

            if (hostValidation.ok) {
              console.log(`  ✓ ${issue.id}: validation passed`);
              break;
            }

            testResult = {
              verdict: "fail",
              summary: "Host macOS on-device validation failed.",
              commands: [hostValidation.command],
              failures: [
                {
                  command: hostValidation.command,
                  exitCode: hostValidation.exitCode,
                  stdout: hostValidation.stdout.slice(-4000),
                  stderr: hostValidation.stderr.slice(-4000),
                },
              ],
            };
          }

          if (attempt === MAX_VALIDATION_FIX_ATTEMPTS) {
            break;
          }

          const validationFixRun = await sandbox.run({
            name: `coder-validation-fixes-${attempt + 1}`,
            maxIterations: 50,
            agent: sandcastle.codex("gpt-5.4-mini"),
            promptFile: "./.sandcastle/lead-delivery/coder-prompt.md",
            promptArgs: {
              MODE: "validation-fixes",
              TASK_ID: issue.id,
              ISSUE_TITLE: issue.title,
              BRANCH: issue.branch,
              BASE_BRANCH,
              ARCHITECTURE: stringify(architecture),
              FEEDBACK: stringify(testResult),
            },
          });
          allCommits.push(...validationFixRun.commits);
        }

        return {
          issue,
          ok: testResult?.verdict === "pass" && hostValidation?.ok === true,
          testResult,
          hostValidation,
          commits: allCommits,
        };
    } finally {
      await sandbox.close();
    }
  }

  for (const [i, outcome] of settled.entries()) {
    if (outcome.status === "rejected") {
      console.error(
        `  ✗ ${issues[i]!.id} (${issues[i]!.branch}) failed: ${outcome.reason}`,
      );
    } else if (!outcome.value.ok) {
      console.error(
        `  ✗ ${outcome.value.issue.id} (${outcome.value.issue.branch}) did not pass validation`,
      );
    }
  }

  const completedIssues = settled
    .filter((outcome): outcome is PromiseFulfilledResult<{
      issue: Issue;
      ok: boolean;
      testResult: TestResult | undefined;
      hostValidation: HostValidationResult | undefined;
      commits: unknown[];
    }> => outcome.status === "fulfilled")
    .filter((outcome) => outcome.value.ok && outcome.value.commits.length > 0)
    .map((outcome) => outcome.value.issue);

  const completedBranches = completedIssues.map((issue) => issue.branch);

  console.log(
    `\nExecution complete. ${completedBranches.length} validated branch(es):`,
  );
  for (const branch of completedBranches) {
    console.log(`  ${branch}`);
  }

  if (completedBranches.length === 0) {
    console.log("No validated branches. Nothing to merge.");
    continue;
  }

  // Phase 3: shared merger merges only branches that passed validation.
  await sandcastle.run({
    hooks,
    sandbox: sandboxProvider,
    name: "merger",
    maxIterations: 1,
    agent: sandcastle.codex("gpt-5.4-mini"),
    promptFile: "./.sandcastle/merge-prompt.md",
    promptArgs: {
      BRANCHES: completedBranches.map((branch) => `- ${branch}`).join("\n"),
      ISSUES: completedIssues
        .map((issue) => `- ${issue.id}: ${issue.title}`)
        .join("\n"),
    },
  });

  console.log("\nValidated branches merged.");
}

console.log("\nLead delivery loop done.");
