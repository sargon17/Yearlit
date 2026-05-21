# Feature: Showcase Native Widget Previews Inside The App

## Goal

Show the app's widgets inside the app using native SwiftUI views, not screenshots.

iOS does not allow embedding real live WidgetKit widgets inside the app. WidgetKit renders outside the app process. The correct implementation is to extract the display-only widget UI into shared SwiftUI components and render those same components from both the widget extensions and the app.

This should improve the onboarding step where `ReadyWidgetsView` currently reserves visual space with `Color.clear`.

## Current State

- Widget targets exist:
  - `YearWidget/YearWidget.swift`
  - `HabitsWidget/HabitsWidget.swift`
- `YearEvaluationWidget` is referenced in project docs, but no matching folder exists in the workspace.
- `My Year`, `YearWidgetExtension`, and `HabitsWidgetExtension` already depend on `SharedModels`.
- Shared widget primitives already exist in `SharedModels/Sources/SharedModels/WidgetStyle.swift`:
  - `WidgetStyle`
  - `WidgetGridDot`
  - `WidgetSeparator`
- Existing onboarding page:
  - `My Year/Views/OnboardingView.swift`
  - `ReadyWidgetsView` currently uses `Color.clear` as its main visual.

## Scope

In scope:

- Add native in-app widget previews using reusable SwiftUI widget views.
- Reuse the same display components in WidgetKit extensions and in the app.
- Show at least the year progress widget and habit progress widget.
- Use preview/sample data where needed.
- Add the preview to onboarding.
- Optionally expose the showcase from settings if the navigation fit is clean.

Out of scope:

- Embedding actual live WidgetKit widgets inside the app.
- Programmatically adding widgets to the Home Screen.
- Screenshot-based previews.
- Rebuilding widget visuals separately in the app.
- Adding or implementing a missing `YearEvaluationWidget` target.

## Implementation Plan

### 1. Extract Display-Only Widget Views Into Shared Code

Create shared widget preview/display files under `SharedModels/Sources/SharedModels/`, for example:

- `YearWidgetContentView.swift`
- `HabitWidgetContentView.swift`
- `WidgetPreviewFamily.swift`
- `WidgetPreviewData.swift` if sample builders need a home

Move or recreate these display-only pieces from the widget targets:

From `YearWidget/YearWidget.swift`:

- Extract `HorizontalYearGrid` into a public shared view.
- Rename it to something app-safe and explicit, for example `YearWidgetContentView`.
- Keep it independent from `TimelineEntry`, `Widget`, and `Provider`.

From `HabitsWidget/HabitsWidget.swift`:

- Extract `HorizontalCalendarGrid` into a public shared view.
- Extract supporting display views:
  - `QuickAddButtonContent`
  - `NumberOfDaysView`
  - `TodaysCountView`
- Keep AppIntent-specific behavior out of the shared view. The shared content should render the visual quick-add affordance, not own the widget action.

### 2. Replace `WidgetFamily` With A Shared Preview Enum

Do not leak `WidgetFamily` deeply into app UI. Introduce a small shared enum:

```swift
public enum WidgetPreviewFamily {
  case small
  case medium
  case large
}
```

Use this enum inside shared display views for dot sizes and layout decisions.

In widget targets, map WidgetKit values at the wrapper boundary:

```swift
extension WidgetPreviewFamily {
  init(_ family: WidgetFamily) {
    switch family {
    case .systemSmall:
      self = .small
    case .systemMedium:
      self = .medium
    default:
      self = .large
    }
  }
}
```

Keep that mapping in the widget target if it needs `WidgetKit`, or behind `#if canImport(WidgetKit)` inside `SharedModels` if cleaner.

### 3. Keep WidgetKit Wrappers Thin

After extraction, `YearWidgetEntryView` should mostly:

- Read WidgetKit environment values.
- Resolve `WidgetStyle.RenderingMode`.
- Resolve background/text colors.
- Call the shared `YearWidgetContentView`.
- Apply WidgetKit-only modifiers:
  - `.containerBackground(..., for: .widget)`
  - `.widgetAccentable(...)`
  - `.widgetURL(...)`

`HabitsWidgetEntryView` should follow the same pattern:

- Resolve destination URL.
- Resolve colors/rendering mode.
- Call shared `HabitWidgetContentView`.
- Apply `.containerBackground` and `.widgetURL` only in the widget target.
- Keep `Button(intent:)` in the WidgetKit layer.

This prevents the app preview from pulling in widget-only behavior.

### 4. Add Deterministic Preview Data

Add deterministic preview builders for in-app previews. The existing `#Preview` helpers at the bottom of `HabitsWidget/HabitsWidget.swift` are a good starting point, but they currently live in the widget target.

Move reusable sample data to shared code or app-only preview code:

- `previewDailyCalendar()`
- `previewMatureCalendar()` if needed
- `previewWeeklyCalendar()` if needed
- `previewDate(year:month:day:)`
- `previewEntries()`

Rules:

- Sample data must be deterministic.
- Do not require the user to have configured widgets on the Home Screen.
- Do not read app storage for the first version unless intentionally showing the user's first real calendar.
- Prefer one clean sample daily habit plus the year widget for the first pass.
- If using real user data later, fall back to sample data when there are no calendars.

### 5. Build `WidgetsShowcaseView` In The App

Add a new app view:

- `My Year/Views/WidgetsShowcaseView.swift`

The view should render native widget previews in fixed-size frames approximating system widget families.

Suggested layout:

- A scrollable page with sections for:
  - Year Progress
  - Habit Progress
- Each section shows small/medium/large variants where useful.
- Use the existing visual system: `AppFont`, `surfaceBackground`, `textPrimary`, `textSecondary`, existing spacing patterns.
- Keep it utilitarian. This is an app page, not a marketing landing page.

Suggested preview frame constants:

```swift
private enum WidgetPreviewSize {
  static let small = CGSize(width: 158, height: 158)
  static let medium = CGSize(width: 338, height: 158)
  static let large = CGSize(width: 338, height: 354)
}
```

The exact dimensions can be tuned visually. The important part is stable aspect ratio and no layout jumping.

### 6. Replace The Onboarding Empty Visual

Update `ReadyWidgetsView` in `My Year/Views/OnboardingView.swift`.

Current issue:

```swift
OnboardingStepContainer {
  Color.clear
} content: {
  ...
}
```

Replace the visual area with one or two native previews, probably:

- Medium habit widget preview.
- Small year progress widget preview, layered or stacked only if it fits cleanly.

Keep the onboarding copy short. The visual should do the work.

### 7. Optionally Add A Settings Entry

Add a row/section in `My Year/Views/Settings.swift` only if there is a clear navigation pattern available.

Possible implementation:

- Add a `Widgets` row near `TimelinePreferenceSection()` or `Features()`.
- Navigate to `WidgetsShowcaseView` using the existing routing/navigation style in the app.

Do not force a new navigation abstraction if settings currently uses simple SwiftUI forms. Match the existing app pattern.

### 8. Keep Widget-Only Modifiers Out Of Shared Views

Shared display views must not own these:

- `.containerBackground(..., for: .widget)`
- `.widgetURL(...)`
- `Button(intent:)`
- WidgetKit `TimelineEntry`
- WidgetKit `Provider`
- WidgetKit `WidgetConfiguration`

Those stay in `YearWidget/YearWidget.swift` and `HabitsWidget/HabitsWidget.swift`.

The app previews should use normal SwiftUI framing/backgrounds and should not pretend to be interactive widgets.

## Validation

Run:

```bash
xcodebuild -scheme "My Year" build
swiftlint lint --quiet
```

If test runtime is available, also run:

```bash
xcodebuild test -scheme "My Year"
```

Manual validation:

- Onboarding widget step shows real native previews, not blank space.
- Year widget still builds in the widget extension.
- Habit widget still builds in the widget extension.
- Widget previews render in light and dark mode.
- Small/medium/large previews do not clip labels or overlap controls.
- Habit preview works when no real calendar exists.
- Widget quick-add still works from the actual Home Screen widget after extraction.

## Acceptance Criteria

- The app has an in-app widget showcase rendered with native SwiftUI views.
- No screenshots are used for widget previews.
- The Home Screen widgets and in-app previews share the same display components.
- WidgetKit-specific wrappers remain in the widget targets.
- Onboarding no longer shows an empty `Color.clear` visual for the widgets step.
- The project builds with `xcodebuild -scheme "My Year" build`.
- Lint passes or any existing lint baseline issues are clearly unrelated.

## Risks

- `HabitsWidget.swift` currently mixes display code with WidgetKit actions. Do not move `Button(intent:)` into shared app code.
- `WidgetFamily` is convenient but should not become app-wide UI state. Convert it at the boundary.
- `SharedModels` already imports SwiftUI and conditionally imports WidgetKit; keep public shared APIs usable by the app target.
- Asset color names such as `text-primary`, `text-tertiary`, `surface-muted`, `qs-orange`, and calendar color strings must resolve correctly from both app and extension bundles.
- The preview page should not imply widgets are already installed. It is a showcase, not widget management.

## Suggested First PR Shape

Keep the first PR narrow:

1. Extract shared year/habit widget content views.
2. Update existing widget wrappers to use the shared views.
3. Add `WidgetsShowcaseView` with sample data.
4. Replace `ReadyWidgetsView` visual content with previews.
5. Build and lint.
