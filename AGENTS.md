before start read `SOUL.md`

## Project Structure & Module Organization

- Primary SwiftUI app lives in `My Year/`; key folders include `Components/`, `Managers/`, `Services/`, and `Views/` for feature code, plus `Config/` for build-time resources.
- Shareable logic is extracted into Swift packages under `SharedModels/` (`Package.swift`, `Sources/SharedModels/`) and widget targets in `YearWidget/`, `YearEvaluationWidget/`, and `HabitsWidget/`.
- Tests sit alongside targets: unit coverage in `My YearTests/`, UI flows in `My YearUITests/`, and widget previews under each widget folder’s `Assets.xcassets`.
- Keep assets, strings, and entitlements in their existing directories; widgets and the app rely on the same app group identifier declared in `*.entitlements`.

## Build, Test, and Development Commands

- `xed .` opens the project in Xcode with the workspace configuration.
- `xcodebuild -scheme "My Year" -destination "platform=iOS Simulator,name=iPhone 15" build` performs a CI-friendly build.
- `xcodebuild test -scheme "My Year" -destination "platform=iOS Simulator,name=iPhone 15"` runs the app, widget, and UI test bundles.
- `swiftlint lint --quiet` enforces the static ruleset (`Baseline.json` suppresses known issues). Run `swiftlint --fix` before submitting formatting-only fixes.
- `swift format --in-place --recursive "My Year" SharedModels/Sources` applies the `.swift-format` conventions when bulk refactoring.

## Coding Style & Naming Conventions

- Follow 2-space indentation, 120-character lines, and ordered imports as enforced by `.swift-format` and `.swiftlint`.
- Prefer `UpperCamelCase` for types, `lowerCamelCase` for properties/functions, and suffix view structs with `View` (e.g., `ProgressRingView`).
- Avoid force unwraps and use early exits sparingly; lint will flag `force_cast`, `force_try`, and long files.
- Place shared utilities in packages rather than the app target to keep dependencies modular.
- Favor componentization: keep views focused, extract reusable UI/logic into dedicated components/files, and add brief comments when they clarify intent.

## Dependency Usage

- Prefer existing dependencies over native alternatives when they cover the need.
- Use `SwiftDate` for date calculations and formatting instead of custom `Calendar`/`DateFormatter` helpers.
- Use `SwiftfulRouting` for navigation, sheets, and routing instead of manual `NavigationStack`/`sheet` wiring where it fits.
- Use `SwiftfulHaptics` for haptic feedback instead of `UIImpactFeedbackGenerator` directly.
- Use `Garnish` for color blending, contrast, and theme helpers instead of ad-hoc color math.
- Use `RevenueCat` and `RevenueCatUI` for subscriptions and paywalls instead of custom purchase flows.
- Use `SharedModels` for cross-target models/types instead of duplicating structs in app/widget targets.
