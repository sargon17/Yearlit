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

# CLOSE ISSUES

For each issue that was merged, close it using:

`gh issue close <issue-id> --comment "Completed by Sandcastle"`

Here are all the issues:

{{ISSUES}}

Once you've merged everything you can, output <promise>COMPLETE</promise>.
