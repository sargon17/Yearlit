# Sandcastle

Default flow:

```sh
bun run sandcastle
```

This runs the lead-delivery loop:

1. Docker sandbox agents plan, implement, review, and run Docker-safe validation.
2. For Swift/iOS build-impacting changes, the orchestrator queues host macOS validation in the branch worktree.
3. Host validation runs:

```sh
bun run check:swift
```

`check:swift` runs `./scripts/xcodebuild-device-build.sh`. The script builds against a connected iOS device when one is available, otherwise it falls back to `generic/platform=iOS`.

SwiftLint remains available as `bun run lint:swift`, but it is not part of host validation because the current baseline has existing violations unrelated to Sandcastle tasks.

This keeps Docker for isolated coding while still testing the iOS app with local Xcode/device toolchains.

## Setup

```sh
bun install
bun run sandcastle:build-image
codex login
gh auth login
```

The orchestrators pass GitHub auth into Docker from `GH_TOKEN`, `GITHUB_TOKEN`, `.sandcastle/.env`, or `gh auth token` on the host. Optional `.sandcastle/.env` can be copied from `.sandcastle/.env.example`.

## Commands

- `bun run sandcastle` — lead-delivery flow with host macOS validation.
- `bun run sandcastle:basic` — copied basic planner/implementer/reviewer/merger flow.
- `bun run sandcastle:build-image` — build the Docker image.
- `bun run check:swift` — local SwiftLint + generic iOS device build.
