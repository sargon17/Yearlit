# TASK

Merge the following branches into the current branch:

{{BRANCHES}}

For each branch:

1. Run `git merge <branch> --no-edit`
2. If there are merge conflicts, resolve them intelligently by reading both sides and choosing the correct resolution
3. After resolving conflicts, run `bun run format:swift` and `bun run lint:swift` if available
4. Do not run iOS Simulator or Xcode build/test commands inside Docker
5. If verification requires Xcode, document `bun run check:swift` instead of running it in the Linux sandbox

After all branches are merged, make a single commit summarizing the merge.

# MARKETING SKILLS

A curated marketing skill bundle is available at `/home/agent/.pi/agent/skills` with an index at `/home/agent/.pi/agent/skills/INDEX.txt`.
You usually do not need it while merging, but if a marketing/product conflict requires semantic judgment, read the relevant skill's `SKILL.md` first.

# CLOSE ISSUES

For each issue that was merged, close it using:

`.sandcastle/scripts/gh-issue.sh close <issue-id>`

Here are all the issues:

{{ISSUES}}

Once you've merged everything you can, output <promise>COMPLETE</promise>.
