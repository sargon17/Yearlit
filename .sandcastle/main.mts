// Parallel Planner with Review — four-phase orchestration loop
//
// This template drives a multi-phase workflow:
//   Phase 1 (Plan):             An opus agent analyzes open issues, builds a
//                               dependency graph, and outputs a <plan> JSON
//                               listing unblocked issues with branch names.
//   Phase 2 (Execute + Review): For each issue, a sandbox is created via
//                               createSandbox(). The implementer runs first
//                               (100 iterations). If it produces commits, a
//                               reviewer runs in the same sandbox on the same
//                               branch (1 iteration). All issue pipelines run
//                               concurrently via Promise.allSettled().
//   Phase 3 (Merge):            A single agent merges all completed branches
//                               into the current branch.
//
// The outer loop repeats up to MAX_ITERATIONS times so that newly unblocked
// issues are picked up after each round of merges.
//
// Usage:
//   bun .sandcastle/main.mts
// Or use package.json:
//   bun run sandcastle:basic
//
// Prefer `bun run sandcastle` / lead-delivery for this iOS app because it also
// runs host macOS generic-device Xcode validation after Docker checks.

import * as sandcastle from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

// Maximum number of plan→execute→merge cycles before stopping.
// Raise this if your backlog is large; lower it for a quick smoke-test run.
const MAX_ITERATIONS = 10;

// Hooks run inside the sandbox before the agent starts each iteration.
// bun install keeps dependencies aligned with bun.lock without generating package-lock.json.
const hooks = {
  sandbox: { onSandboxReady: [{ command: "bun install --frozen-lockfile" }] },
};

// Copy node_modules from the host into the worktree before each sandbox
// starts. Avoids a full bun install from scratch; the hook above handles
// platform-specific binaries and any packages added since the last copy.
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

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

for (let iteration = 1; iteration <= MAX_ITERATIONS; iteration++) {
  console.log(`\n=== Iteration ${iteration}/${MAX_ITERATIONS} ===\n`);

  // -------------------------------------------------------------------------
  // Phase 1: Plan
  //
  // The planning agent (opus, for deeper reasoning) reads the open issue list,
  // builds a dependency graph, and selects the issues that can be worked in
  // parallel right now (i.e., no blocking dependencies on other open issues).
  //
  // It outputs a <plan> JSON block — we parse that to drive Phase 2.
  // -------------------------------------------------------------------------
  const plan = await sandcastle.run({
    hooks,
    sandbox: sandboxProvider,
    name: "planner",
    // One iteration is enough: the planner just needs to read and reason,
    // not write code.
    maxIterations: 1,
    // Opus for planning: dependency analysis benefits from deeper reasoning.
    agent: sandcastle.codex("gpt-5.4-mini"),
    promptFile: "./.sandcastle/plan-prompt.md",
  });

  // Extract the <plan>…</plan> block from the agent's stdout.
  const planMatch = plan.stdout.match(/<plan>([\s\S]*?)<\/plan>/);
  if (!planMatch) {
    throw new Error(
      "Planning agent did not produce a <plan> tag.\n\n" + plan.stdout,
    );
  }

  // The plan JSON contains an array of issues, each with id, title, branch.
  const { issues } = JSON.parse(planMatch[1]!) as {
    issues: { id: string; title: string; branch: string }[];
  };

  if (issues.length === 0) {
    // No unblocked work — either everything is done or everything is blocked.
    console.log("No unblocked issues to work on. Exiting.");
    break;
  }

  console.log(
    `Planning complete. ${issues.length} issue(s) to work in parallel:`,
  );
  for (const issue of issues) {
    console.log(`  ${issue.id}: ${issue.title} → ${issue.branch}`);
  }

  // -------------------------------------------------------------------------
  // Phase 2: Execute + Review
  //
  // For each issue, create a sandbox via createSandbox() so the implementer
  // and reviewer share the same sandbox instance per branch. The implementer
  // runs first; if it produces commits, the reviewer runs in the same sandbox.
  //
  // Promise.allSettled means one failing pipeline doesn't cancel the others.
  // -------------------------------------------------------------------------

  const settled = await Promise.allSettled(
    issues.map(async (issue) => {
      const sandbox = await sandcastle.createSandbox({
        branch: issue.branch,
        sandbox: sandboxProvider,
        hooks,
        copyToWorktree,
      });

      try {
        // Run the implementer
        const implement = await sandbox.run({
          name: "implementer",
          maxIterations: 100,
          agent: sandcastle.codex("gpt-5.4-mini"),
          promptFile: "./.sandcastle/implement-prompt.md",
          promptArgs: {
            TASK_ID: issue.id,
            ISSUE_TITLE: issue.title,
            BRANCH: issue.branch,
          },
        });

        // Only review if the implementer produced commits
        if (implement.commits.length > 0) {
          const review = await sandbox.run({
            name: "reviewer",
            maxIterations: 1,
            agent: sandcastle.codex("gpt-5.4-mini"),
            promptFile: "./.sandcastle/review-prompt.md",
            promptArgs: {
              BRANCH: issue.branch,
            },
          });

          // Merge commits from both runs so the merge phase sees all of them.
          // Each sandbox.run() only returns commits from its own run.
          return {
            ...review,
            commits: [...implement.commits, ...review.commits],
          };
        }

        return implement;
      } finally {
        await sandbox.close();
      }
    }),
  );

  // Log any agents that threw (network error, sandbox crash, etc.).
  for (const [i, outcome] of settled.entries()) {
    if (outcome.status === "rejected") {
      console.error(
        `  ✗ ${issues[i]!.id} (${issues[i]!.branch}) failed: ${outcome.reason}`,
      );
    }
  }

  // Only pass branches that actually produced commits to the merge phase.
  // An agent that ran successfully but made no commits has nothing to merge.
  const completedIssues = settled
    .map((outcome, i) => ({ outcome, issue: issues[i]! }))
    .filter(
      (entry) =>
        entry.outcome.status === "fulfilled" &&
        entry.outcome.value.commits.length > 0,
    )
    .map((entry) => entry.issue);

  const completedBranches = completedIssues.map((i) => i.branch);

  console.log(
    `\nExecution complete. ${completedBranches.length} branch(es) with commits:`,
  );
  for (const branch of completedBranches) {
    console.log(`  ${branch}`);
  }

  if (completedBranches.length === 0) {
    // All agents ran but none made commits — nothing to merge this cycle.
    console.log("No commits produced. Nothing to merge.");
    continue;
  }

  // -------------------------------------------------------------------------
  // Phase 3: Merge
  //
  // One agent merges all completed branches into the current branch,
  // resolving any conflicts and running tests to confirm everything works.
  //
  // The {{BRANCHES}} and {{ISSUES}} prompt arguments are lists that the agent
  // uses to know which branches to merge and which issues to close.
  // -------------------------------------------------------------------------
  await sandcastle.run({
    hooks,
    sandbox: sandboxProvider,
    name: "merger",
    maxIterations: 1,
    agent: sandcastle.codex("gpt-5.4-mini"),
    promptFile: "./.sandcastle/merge-prompt.md",
    promptArgs: {
      // A markdown list of branch names, one per line.
      BRANCHES: completedBranches.map((b) => `- ${b}`).join("\n"),
      // A markdown list of issue IDs and titles, one per line.
      ISSUES: completedIssues
        .map((i) => `- ${i.id}: ${i.title}`)
        .join("\n"),
    },
  });

  console.log("\nBranches merged.");
}

console.log("\nAll done.");
