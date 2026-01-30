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

## Widgets
This repo contains multiple widget targets. After installing the app on a simulator/device:
1. Long-press the Home Screen → **Edit** → **Add Widget**
2. Add the Yearlit widgets (Habits / Streak / Year)

## Notes
- Formatting/lint config lives in `.swift-format` and `.swiftlint.yml`.
- If you hit signing issues, open the project settings and set your development team for each target.

---

If you want, add a short description, screenshots, and a roadmap in this README.
