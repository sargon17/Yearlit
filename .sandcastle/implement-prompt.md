# TASK

Fix issue {{TASK_ID}}: {{ISSUE_TITLE}}

Pull in the issue using `gh issue view {{TASK_ID}}`. If it has a parent PRD, pull that in too.

Only work on the issue specified.

Work on branch {{BRANCH}}. Make commits and run tests.

# CONTEXT

A curated marketing skill bundle is available at `/home/agent/.pi/agent/skills` with an index at `/home/agent/.pi/agent/skills/INDEX.txt`.
If the issue involves marketing, growth, SEO, ASO, copy, pricing, paywalls, onboarding, CRO, analytics, launch, referrals, customer research, ads, email, social, or positioning, read the relevant skill's `SKILL.md` before implementing.

Here are the last 10 commits:

<recent-commits>

!`git log -n 10 --format="%H%n%ad%n%B---" --date=short`

</recent-commits>

# EXPLORATION

Explore the repo and fill your context window with relevant information that will allow you to complete the task.

Pay extra attention to test files that touch the relevant parts of the code.

# EXECUTION

If applicable, use RGR to complete the task.

1. RED: write one test
2. GREEN: write the implementation to pass that test
3. REPEAT until done
4. REFACTOR the code

# FEEDBACK LOOPS

Before committing:

1. Run `bun run format:swift` if available.
2. Run `bun run lint:swift` if useful, but only treat violations introduced by your diff as blocking.
3. Do not run iOS Simulator commands inside Docker. macOS host validation must run `bun run check:swift`, which builds with a connected iOS device when available and otherwise uses a generic iOS device destination.
4. If verification requires Xcode, document `bun run check:swift` instead of running Xcode in the Linux sandbox.

# COMMIT

Make a git commit. The commit message must:

1. Start with `RALPH:` prefix
2. Include task completed + PRD reference
3. Key decisions made
4. Files changed
5. Blockers or notes for next iteration

Keep it concise.

# THE ISSUE

If the task is not complete, leave a comment on the issue with what was done.

Do not close the issue - this will be done later.

Once complete, output <promise>COMPLETE</promise>.

# FINAL RULES

ONLY WORK ON A SINGLE TASK.
