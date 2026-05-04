# Coding Standards

## Project shape

- Primary SwiftUI app code lives in `My Year/`.
- Shared cross-target models belong in `SharedModels/Sources/SharedModels/`.
- Widget targets live in `YearWidget/`, `YearEvaluationWidget/`, `HabitsWidget/`, and `StreakWidget/`.
- Keep entitlements, assets, and localized resources in their existing target folders.

## Swift style

- Follow `.swift-format` and `.swiftlint.yml`.
- Use 2-space indentation and keep lines near 120 characters.
- Use `UpperCamelCase` for types and `lowerCamelCase` for members.
- Suffix SwiftUI views with `View`.
- Avoid force unwraps, force casts, and force tries.
- Prefer small focused SwiftUI components over large views.

## Dependencies

- Prefer existing dependencies over new custom helpers.
- Use SwiftDate for date calculations/formatting.
- Use SwiftfulRouting for navigation/sheets where it fits.
- Use SwiftfulHaptics for haptics.
- Use Garnish for color blending/contrast/theme helpers.
- Use RevenueCat/RevenueCatUI for subscriptions and paywalls.
- Use SharedModels for shared app/widget types.

## Validation

- Docker Sandcastle agents must not run Xcode or simulator commands.
- For Swift changes, run available Docker-safe checks only (`bun run format:swift:check`, `bun run lint:swift`).
- The lead-delivery orchestrator runs `bun run check:swift` on the macOS host for iOS build-impacting changes. This uses a connected iOS device when available, otherwise a generic iOS device build; validation is not Docker-only.
- SwiftLint is available via `bun run lint:swift`, but pre-existing violations outside the task diff are not blockers.
