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

**Calendar**:
A user-created tracker for repeated progress across days or weeks. A Calendar may track binary completion, numeric counts, or a target count.
_Avoid_: Habit or Goal when referring to the stored product object

**Check-in**:
The first logged progress for a Calendar period, such as checking off a day, recording a count, or adding progress toward a target.
_Avoid_: Entry when speaking about user-facing behavior

**Period**:
The day or week a Calendar is tracking, depending on its cadence.
_Avoid_: Day when the Calendar may be weekly

**Period completed**:
A Period reaches the Calendar's completion criteria. Binary Calendars complete when checked off. Target Calendars complete when the target count is reached. Counter Calendars do not have completion semantics unless a target is added.
_Avoid_: Day completed for weekly-capable behavior

**Calendar automation**:
A Calendar setup where Check-ins are filled without direct user logging.
_Avoid_: Automatic Calendar when naming the user-facing choice

**Connected Calendar**:
A Calendar whose Check-ins are filled from an external data source.
_Avoid_: Automated habit, manual alternative

**Mood Tracking**:
The optional feature where users record whether a day felt terrible, bad, neutral, good, or excellent, with optional journal text.
_Avoid_: Tracking mood values in analytics unless explicitly scoped

**Recap View**:
The optional year-level reflective view summarizing progress across Calendars.
_Avoid_: Overview when naming events or code-facing analytics

**Onboarding flow**:
The first-run guided experience that introduces Yearlit, collects setup choices, and may adapt later steps based on earlier answers.
_Avoid_: Intro slides when referring to the full interactive setup experience

**Onboarding session**:
The temporary set of answers and setup choices collected while a user is inside the Onboarding flow.
_Avoid_: Persisted onboarding state, user profile, settings

**Onboarding step**:
A typed screen in the Onboarding flow, such as a story step, choice step, setup step, permission step, or paywall step.
_Avoid_: Slide when the screen can be interactive or branching

**Identity commitment**:
A self-image a user can select during onboarding to shape suggested Tiny habits.
_Avoid_: Category, persona, habit type

**Tiny habit**:
A small starter action proposed during onboarding and used to create the user's first Calendar.
_Avoid_: Goal, task, template when speaking to users

**First dot**:
The first completed Period shown during onboarding to make the user's first Calendar feel real.
_Avoid_: Sample dot, fake completion

**First Calendar**:
The Calendar a user starts during onboarding, or the earliest existing active Calendar if onboarding restarts after setup began.
_Avoid_: Onboarding calendar, sample calendar

**Apple Health connected Calendar**:
A Calendar whose progress is filled from a supported Apple Health metric while remaining editable like a normal Calendar.
_Avoid_: Health habit, Health tracker, Apple Health calendar

**Apple Health metric**:
A supported Apple Health quantity used to fill a Calendar, such as Steps, Active Energy, Exercise Minutes, Walking + Running Distance, or Flights Climbed.
_Avoid_: Health integration, Apple Health data, activity data when a specific metric is meant

**Daily Wallpaper**:
A dark Yearlit-generated image intended to be applied as an iPhone wallpaper by a Shortcuts automation.
_Avoid_: bg, background pipeline

**Year Progress**:
The current year visualization based on elapsed days, today, future days, percent complete, and days left.
_Avoid_: habit wallpaper, calendar wallpaper

**Daily Wallpaper Shortcut**:
The iOS Shortcut automation that runs Yearlit's **Create Daily Wallpaper** action and Apple's **Set Wallpaper** action.
_Avoid_: bg shortcut, pipeline

**Daily Wallpaper settings**:
The in-app configuration that chooses how Yearlit renders the next **Daily Wallpaper**.
_Avoid_: Shortcut settings, automation parameters

**Daily Wallpaper template**:
A fixed visual recipe for rendering **Year Progress** inside a **Daily Wallpaper**.
_Avoid_: habit wallpaper template, calendar wallpaper template, data source

**Daily Wallpaper theme**:
The light or dark color mode used by a **Daily Wallpaper template**.
_Avoid_: template when only the light or dark mode changes

**Daily Wallpaper accent color**:
The color used for active **Year Progress** elements inside a **Daily Wallpaper**, such as the current-day dot and the highlighted progress number.
_Avoid_: active color, brand color, theme color

**Daily Wallpaper message**:
A user-written line rendered by premium message-capable **Daily Wallpaper templates**.
_Avoid_: quote, caption, reminder text

**Data backup**:
An automatic local recovery point containing all durable user-created Yearlit data.
_Avoid_: Debug backup, snapshot, versioning

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
- An **Onboarding flow** is made of ordered and branching **Onboarding steps**.
- An **Onboarding session** belongs to exactly one in-progress **Onboarding flow**.
- **Onboarding steps** may read and update the **Onboarding session**, but only setup steps that create durable product objects should write to app stores.
- A user may select and deselect multiple **Identity commitments** during onboarding.
- The last selected **Identity commitment** produces a short list of candidate **Tiny habits**.
- The user must have at least one selected **Identity commitment** before continuing to **Tiny habit** selection.
- The **Onboarding flow** sequence is: emotional hook, app explanation, **Identity commitment**, **Tiny habit** selection, **First dot**, feedback gate, optional review request, notification permission, ready/widgets, paywall, then app entry.
- Selecting a **Tiny habit** creates the user's **First Calendar**.
- Marking the **First dot** creates a real **Check-in** for the **First Calendar**.
- If the **Onboarding flow** restarts after setup began, an existing active **Calendar** is treated as the **First Calendar** instead of creating a duplicate.
- A **Calendar automation** is any Calendar setup where Check-ins are filled without direct user logging.
- A **Connected Calendar** is a kind of **Calendar automation** backed by an external data source.
- The Calendar creation flow first asks whether the user wants to log Check-ins themselves or create a **Connected Calendar**.
- The Calendar creation entry screen is titled "Create Calendar" and asks "How do you want to track progress?"
- Choosing to track Check-ins manually opens the existing Calendar creation form rather than a new multi-step flow.
- The self-tracked Calendar creation form does not show data source selection because the source is already resolved.
- The self-tracked Calendar creation form is named as a manual Calendar creation flow in code, not as the generic Calendar creation flow.
- Yearlit checks the Calendar limit immediately after the user chooses to create a **Connected Calendar**, before source selection or permission prompts.
- **Connected Calendar** source selection shows available sources only until future sources are ready to configure.
- **Connected Calendar** source selection is a stable creation step even when only one source is currently available.
- The first **Connected Calendar** source picker uses a flat list rather than grouping sources by family.
- Yearlit requests external data access during **Connected Calendar** source setup, before the final Calendar configuration step.
- Apple Health permission setup has one primary action: connecting Apple Health.
- Apple Health source setup tells users that Yearlit only reads the selected metric and does not write to Apple Health.
- **Connected Calendar** setup explains what will be imported, but does not preview imported Check-ins before final creation.
- Creating an **Apple Health connected Calendar** imports current-year metric history as part of the final create action.
- Apple Health Steps Calendar configuration explains that Yearlit imports step counts from January 1 through today and leaves days without Apple Health data empty.
- After creating a Calendar, Yearlit shows the newly created Calendar immediately.
- Yearlit does not prevent users from creating multiple Calendars from the same connected source.
- An **Apple Health connected Calendar** is still a **Calendar**; Apple Health is only the source used to fill its progress.
- The first Apple Health release stores the selected **Apple Health metric** in the Calendar source.
- **Apple Health connected Calendars** support Steps, Active Energy, Exercise Minutes, Walking + Running Distance, and Flights Climbed.
- Apple Health connected Calendar detail screens show the Apple Health source subtly enough to explain sync and disabled manual editing.
- Apple Health metric Calendar configuration only asks for Calendar name, color, and daily target.
- In the first Apple Health release, **Apple Health connected Calendars** are daily-only.
- The first Apple Health release does not support manual overrides on **Apple Health connected Calendars**.
- Apple Health sync owns the Check-ins it creates for an **Apple Health connected Calendar**.
- The first Apple Health release disables manual Check-in editing on **Apple Health connected Calendars**.
- **Apple Health Steps metric** imports daily step counts and completes a Period when the count reaches the Calendar target.
- Apple Health Steps Calendars do not use Calendar Check-in reminders.
- Users can edit **Apple Health connected Calendar** metadata such as name, color, target, archive state, and deletion.
- Apple Health connected Calendar edit screens do not show Calendar Check-in reminder settings.
- The first Apple Health release does not let users edit the cadence, tracking type, unit, or source of an **Apple Health connected Calendar**.
- Changing the target of an **Apple Health connected Calendar** recomputes Period completion from imported metric values.
- The first Apple Health release does not support disconnecting Apple Health from an **Apple Health connected Calendar**.
- A user who no longer wants an **Apple Health connected Calendar** deletes the Calendar.
- The first Apple Health release introduces **Apple Health connected Calendars** through the normal Calendar creation flow only.
- Onboarding, announcement sheets, and other surfaces may introduce **Apple Health connected Calendars** later, but are not part of the first implementation.
- The 1.15 announcement sheet for **Apple Health connected Calendars** is deferred until the core Calendar creation path works.
- Health access is free, but **Apple Health connected Calendars** count toward the same free Calendar limit as manual Calendars.
- Yearlit checks the Calendar limit before requesting Apple Health permission.
- Only the app reads Apple Health in the first Apple Health release; widgets read the resulting Calendar data.
- Apple Health sync runs during Calendar creation, app launch, foreground, and Apple Health Calendar detail open.
- Manual Apple Health sync is hidden from normal users and reserved for developer/debug controls.
- Apple Health sync replaces current-year Apple Health-owned Check-ins from January 1 through today.
- If Apple Health permission is revoked, sync leaves existing Check-ins unchanged and shows that permission is needed.
- Apple Health import and sync suppress **Milestone celebrations** while silently remembering reached **Milestones**.
- If Apple Health permission is denied during Calendar creation, Yearlit keeps the user in the creation flow and offers a manual Calendar fallback without automatically creating the Calendar.
- If Apple Health permission is denied during **Connected Calendar** source setup, Yearlit shows a permission-needed state with actions to open Settings or switch to tracking manually.
- If Apple Health permission is granted but no current-year metric history exists, Yearlit still creates an empty **Apple Health connected Calendar**.
- An **Apple Health metric** Calendar is a target Calendar whose Period is completed when the daily imported value reaches the Calendar target.
- Default Apple Health targets are 8,000 steps, 300 active calories, 30 exercise minutes, 5,000 meters, and 10 flights per day.
- An **Apple Health metric** Calendar starts on January 1 of the current year for current-year backfill.
- Days without samples for the selected Apple Health metric remain empty.
- The first Apple Health release does not convert existing manual Calendars into **Apple Health connected Calendars**.
- The Apple Health source is chosen only when creating a new **Apple Health connected Calendar**.
- Additional Apple Health metrics are added through the shared **Apple Health metric** model without changing the **Calendar** concept.
- A **Daily Wallpaper Shortcut** produces one **Daily Wallpaper** each time it runs.
- A **Daily Wallpaper** is applied by Shortcuts, not directly by Yearlit.
- A **Daily Wallpaper** uses **Year Progress** data and is sized for the natural iPhone wallpaper aspect ratio.
- **Daily Wallpaper settings** live in Yearlit, not in the **Daily Wallpaper Shortcut**.
- The **Daily Wallpaper Shortcut** runs the same **Create Daily Wallpaper** action regardless of the selected template, theme, color, or message.
- A **Daily Wallpaper template** changes presentation only; it does not change the **Year Progress** data shown by the **Daily Wallpaper**.
- The Classic **Daily Wallpaper template** is free.
- The initial premium **Daily Wallpaper templates** are Large Clock and Minimal.
- Large Clock and Minimal support rendering a **Daily Wallpaper message**.
- The light and dark **Daily Wallpaper themes** are free for the Classic **Daily Wallpaper template**.
- **Daily Wallpaper theme** selection is manual; it does not automatically follow system appearance.
- The default **Daily Wallpaper theme** is dark to preserve existing behavior.
- Additional **Daily Wallpaper templates** and customization options may be premium.
- A **Daily Wallpaper accent color** customizes the active progress highlight, not the whole template palette.
- Free users use the default Yearlit orange **Daily Wallpaper accent color**.
- Premium users can customize the **Daily Wallpaper accent color**.
- A **Daily Wallpaper message** is only available on premium **Daily Wallpaper templates** that explicitly support rendering it.
- The Classic **Daily Wallpaper template** is the default full-grid wallpaper and does not render a **Daily Wallpaper message**.
- A **Daily Wallpaper message** is optional, trimmed, rendered in up to two centered lines, and limited to 40 characters.
- Empty **Daily Wallpaper message** text means no message is rendered.
- When premium access is inactive or unknown, **Create Daily Wallpaper** renders with free defaults: Classic template, a free light or dark theme, the default Yearlit orange **Daily Wallpaper accent color**, and no **Daily Wallpaper message**.
- Losing premium access does not delete saved premium **Daily Wallpaper settings**; those choices can apply again if premium access returns.
- A **Data backup** includes all durable user-created data: **Calendars**, **Check-ins**, **Mood Tracking** valuations and journal notes, and Habit Stacks.
- A **Data backup** does not include ephemeral app state such as analytics flags, onboarding progress, paywall state, or widget UI state.
- A **Data backup** includes **Check-ins** imported for **Apple Health connected Calendars**.
- Apple Health sync may replace restored **Check-ins** for **Apple Health connected Calendars** after restore.
- Yearlit creates **Data backups** automatically without user action.
- Yearlit keeps changed automatic **Data backups** for ninety days and keeps only the newest twenty protective **Data backups**.
- Yearlit creates a **Data backup** before migrations or bulk destructive operations.
- Yearlit stores **Data backups** locally in the app group as app-managed files.
- Yearlit stores **Data backups** as versioned JSON domain data rather than raw SwiftData entity dumps.
- Yearlit does not apply custom encryption to **Data backups** in the first implementation.
- Yearlit creates at most one normal automatic **Data backup** per day when durable user-created data changed.
- Yearlit identifies changed durable user-created data with a stable data fingerprint that excludes backup metadata.
- Protective **Data backups** created before risky operations are not limited by the daily automatic backup cap.
- Users restore a **Data backup** from iPhone app Settings when they need to recover lost or corrupted data.
- **Data backup** restore is available from normal Settings instead of being gated by **Developer mode**.
- Restoring a **Data backup** fully replaces current durable user-created data instead of merging records.
- Yearlit creates a fresh **Data backup** immediately before restoring another **Data backup**.
- A **Data backup** shown for restore includes its creation time, reason, app version, and counts for Calendars, Check-ins, Mood Tracking entries, journal notes, and Habit Stacks.
- Settings only shows validated, restorable **Data backups**.
- Corrupt **Data backups** and backups from unsupported future schema versions are hidden from the restore list and logged.
- Users can restore **Data backups** but do not manually delete, export, or import them.
- Yearlit manages **Data backup** deletion through retention rules.
- Failed normal automatic **Data backup** creation does not block normal app use.
- Failed protective **Data backup** creation blocks restore and any controlled risky operation that depends on that backup.
- After restoring a **Data backup**, Yearlit reloads app state and widgets without requiring an app restart.
- **Create Daily Wallpaper** reads cached premium status when enforcing premium **Daily Wallpaper settings**.
- **Create Daily Wallpaper** does not block generation on a live purchase-status network request.

## Example dialogue

> **Dev:** "If a user disables **Milestone celebrations**, should we stop detecting **Milestones**?"
> **Domain expert:** "No — keep detecting them silently so old **Milestone celebrations** do not spam the user later."

> **Dev:** "Should Yearlit set the user's wallpaper directly?"
> **Domain expert:** "No. Yearlit generates the **Daily Wallpaper**; the **Daily Wallpaper Shortcut** applies it through Apple's Shortcuts actions."

> **Dev:** "Should the **Daily Wallpaper** include habit completion?"
> **Domain expert:** "No. It should show **Year Progress**, matching the Year widget's data semantics."

## Flagged ambiguities

- "Switch milestones off" was resolved to mean disabling **Milestone celebrations**, not deleting or pausing **Milestone** detection/history.
- "Customize milestones" was resolved to mean changing **Milestone celebration settings**, while keeping milestone detection intact.
- "Fake calendar" was resolved to **Marketing demo calendar**: normal calendar content used by the developer for marketing screenshots.
- "bg" was used to mean wallpaper. Resolved: use **Daily Wallpaper** for the generated image and **Daily Wallpaper Shortcut** for the automation.
