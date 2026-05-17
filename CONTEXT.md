# Yearlit

Yearlit helps people track calendar-based habits and reflect on progress without turning progress feedback into interruption.

## Language

**Milestone**:
A progress threshold reached by a calendar, such as a streak length or a showed-up count.
_Avoid_: Achievement, badge

**Milestone celebration**:
The celebratory in-app experience shown when a milestone is reached, with sharing as a secondary action.
_Avoid_: Milestone notification, milestone share sheet, milestone tracking, milestone history, StreakMilestoneShareSheet

**Milestone celebration settings**:
Global user preferences that decide which reached milestones interrupt the user with a milestone celebration.
_Avoid_: Milestone notification settings, milestone settings, achievement settings

**Streak milestone celebration**:
A milestone celebration for consecutive successful periods on a calendar.
_Avoid_: Streak alert

**Showed-up milestone celebration**:
A milestone celebration for total successful periods on a calendar.
_Avoid_: Attendance alert

**Recap milestone celebration**:
A milestone celebration for successful periods within the current month or current year.
_Avoid_: Monthly milestone, yearly milestone

**Settings**:
The app-level area where a user changes global Yearlit behavior.
_Avoid_: Preferences

**Marketing demo calendar**:
A normal calendar used by the developer to produce shareable marketing screenshots.
_Avoid_: Fake calendar, sample calendar

**Developer mode**:
A hidden production-accessible mode for trusted developer-only tooling.
_Avoid_: Debug mode, secret mode

## Relationships

- A **Calendar** can reach many **Milestones**.
- A **Milestone celebration** belongs to exactly one reached **Milestone**.
- Sharing a **Milestone celebration** is optional and secondary.
- Debug-only **Milestone celebration** previews are not part of the product behavior and should be removed.
- Disabling **Milestone celebrations** does not disable **Milestone** detection or progress tracking.
- **Milestone celebration settings** live in **Settings**, apply to all Calendars, are app-only, and are stored as one settings object rather than scattered individual view keys.
- **Milestone celebration settings** have a master switch and can separately switch **Streak milestone celebrations**, **Showed-up milestone celebrations**, and **Recap milestone celebrations** on or off.
- Turning the master switch off disables category switches visually but preserves their values.
- Existing remembered **Milestones** are preserved when milestone schedules change.
- When any **Milestone celebration** category is off, reached **Milestones** in that category are remembered silently instead of queued for later.
- A **Milestone celebration** can offer “Stop showing this kind” to turn off future celebrations of the same category.
- Celebration categories turned off from a **Milestone celebration** can be re-enabled in **Settings**.
- Turning off a category from a **Milestone celebration** marks the current **Milestone** as remembered, then closes the current celebration immediately.
- **Milestone celebration settings** default to showing reduced-frequency **Milestone celebrations**, not every possible milestone.
- When enabled, **Streak milestone celebrations** use the schedule: 3, 7, 14, 30, 50, 100, then every 100 successful periods in a row.
- When enabled, **Showed-up milestone celebrations** use the schedule: 10, 25, 50, 100, 250, 500, then every 500 successful periods.
- By default, the master switch is on, **Streak milestone celebrations** are on, **Showed-up milestone celebrations** are on, and **Recap milestone celebrations** are off.
- A **Marketing demo calendar** is stored and behaves like any other Calendar.
- **Developer mode** can expose **Marketing demo calendar** tools in production, but only after deliberate hidden activation.
- **Developer mode** only reveals developer-only tools; it does not change normal calendar, paywall, notification, milestone, or tracking behavior by itself.
- **Developer mode** is enabled by tapping the app icon in the Settings footer ten times.
- Once enabled, **Developer mode** persists across app launches until manually disabled.
- When **Developer mode** is enabled, Calendar detail screens show the same wand-fill action used in debug builds.
- The wand-fill action keeps the same behavior in production **Developer mode** as in debug builds, including clearing and randomly refilling entries.
- Enabling **Developer mode** gives subtle confirmation rather than interrupting normal Settings use.
- **Developer mode** controls live near the wand-fill settings in Settings.
- In production **Developer mode**, wand-fill settings are visible without enabling runtime debug.

## Example dialogue

> **Dev:** "If a user disables **Milestone celebrations**, should we stop detecting **Milestones**?"
> **Domain expert:** "No — keep detecting them silently so old **Milestone celebrations** do not spam the user later."

## Flagged ambiguities

- "Switch milestones off" was resolved to mean disabling **Milestone celebrations**, not deleting or pausing **Milestone** detection/history.
- "Customize milestones" was resolved to mean changing **Milestone celebration settings**, while keeping milestone detection intact.
- "Fake calendar" was resolved to **Marketing demo calendar**: normal calendar content used by the developer for marketing screenshots.
