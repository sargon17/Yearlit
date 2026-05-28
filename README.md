# Yearlit

**Yearlit** is an iOS app project (Xcode) focused on year-level tracking and widgets (habits/streaks/year).

## What’s in this repo
- `My Year.xcodeproj` – main Xcode project
- `My Year/` – iOS app source
- `SharedModels/` – shared models used across targets
- `HabitsWidget/`, `StreakWidget/`, `YearWidget/` – widget extensions

## Requirements
- macOS with **Xcode** installed
- iOS target devices/simulators supported by the project settings

## Run locally
1. Clone the repo
2. Open **`My Year.xcodeproj`** in Xcode
3. Select a simulator/device
4. Build & Run (`⌘R`)

## Zed + SourceKit
Zed uses `sourcekit-lsp` for Swift completions, diagnostics, and go-to-definition. This project is an Xcode project, so SourceKit needs compiler arguments generated from an Xcode build.

Run this after cloning, changing targets/build settings, adding Swift files, or when Zed stops resolving symbols correctly:

```sh
bun run sourcekit:refresh
```

The command builds the `My Year` scheme, refreshes `buildServer.json`, and updates `.compile` for `xcode-build-server`.

Notes:
- Install `xcode-build-server` first if the command says it is missing.
- Restart Zed or restart the Swift language server after refreshing SourceKit config.
- On macOS, use `⌘+Click` for go-to-definition. `Ctrl+Click` is not the Zed macOS shortcut and may open the system context menu.

## Widgets
This repo contains multiple widget targets. After installing the app on a simulator/device:
1. Long-press the Home Screen → **Edit** → **Add Widget**
2. Add the Yearlit widgets (Habits / Streak / Year)

## Notes
- Formatting/lint config lives in `.swift-format` and `.swiftlint.yml`.
- If you hit signing issues, open the project settings and set your development team for each target.

---

If you want, add a short description, screenshots, and a roadmap in this README.
