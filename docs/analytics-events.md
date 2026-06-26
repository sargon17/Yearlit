# Analytics Events

Yearlit analytics exists to answer product and marketing questions without collecting sensitive user-entered content.

## Privacy rules

Never send these values to analytics:

- `calendar_name`
- `calendar_names`
- `habit_name`
- `habit_names`
- `goal_text`
- `journal_note`
- `journal_notes`
- `mood_note`
- `mood_note_text`
- `notification_text`
- Calendar names
- Habit names
- Goal text
- Journal notes
- Mood note text
- Notification text
- Any other user-entered sensitive content

Prefer booleans, counts, feature state, coarse configuration, and event names.

## Standard properties

Every app-owned event should include the standard analytics snapshot:

- `days_since_install`
- `app_version`
- `build_number`
- `app_locale_language`
- `revenuecat_app_user_id`
- `apple_ads_adservices_enabled`
- `is_premium`
- `premium_status_known`
- `mood_tracking_enabled`
- `recap_view_enabled`
- `milestone_celebrations_enabled`
- `streak_milestone_celebrations_enabled`
- `showed_up_milestone_celebrations_enabled`
- `recap_milestone_celebrations_enabled`
- `calendar_count`
- `active_calendar_count`
- `archived_calendar_count`
- `daily_calendar_count`
- `weekly_calendar_count`
- `binary_calendar_count`
- `counter_calendar_count`
- `target_calendar_count`
- `calendar_with_reminder_count`
- `has_reminders_enabled`
- `has_completed_activation`
- `has_completed_first_checkin`
- `has_completed_first_period`

The same non-sensitive state may be set as PostHog person properties.

## Catalog hardening

Allowed `paywall_trigger` values: `onboarding`, `calendar_limit`, `share_gate`, `stats_gate`, `notification_gate`, `settings_support`, `automatic_positive_event`, `automatic_timed`, `unknown`.

Allowed `paywall_variant` values: `default`, `commitment_protection_v1`.

Allowed `package_type` values: `annual`, `monthly`, `weekly`, `unknown`.

Allowed paywall `error_category` values: `network`, `purchase_failed`, `restore_failed`, `unknown`.

Allowed `share_type` values: `calendar`, `recap`, `unknown`.

Forbidden sensitive content categories:

- calendar names
- habit names
- goal text
- journal notes
- mood note text
- notification text
- any other user-entered sensitive content

Forbidden property names:

- `calendar_name`
- `calendar_names`
- `habit_name`
- `habit_names`
- `goal_text`
- `journal_note`
- `journal_notes`
- `mood_note`
- `mood_note_text`
- `notification_text`

## Base lifecycle events

| Event | Fires when | Extra properties |
| --- | --- | --- |
| `app_opened` | App enters foreground/active state. | Standard properties only. |
| `onboarding_started` | Onboarding first appears once per install. | Standard properties only. |
| `onboarding_completed` | Onboarding is marked as seen. | Standard properties only. |

## Onboarding funnel events

Owned by #99.

| Event | Notes |
| --- | --- |
| `onboarding_step_viewed` | Fires when the onboarding coordinator transitions to a step that is actually shown. Include only `step_id`. Allowed `step_id` values: `emotional_hook`, `app_explanation`, `identity_commitment`, `tiny_habit_selection`, `first_dot`, `notification_permission`, `ready_widgets`, `paywall`. |
| `onboarding_action_performed` | Fires for coarse onboarding actions only. Include only `action`. Allowed `action` values: `identity_completed`, `tiny_habit_created`, `first_dot_marked`, `notifications_requested`, `notifications_skipped`, `ready_continued`, `paywall_boundary_reached`, `paywall_closed`. |

Do not send identity commitment IDs, tiny habit IDs, selected habit strings, calendar IDs, calendar names, habit names, notification text, notes, goal text, or any other user-entered content in these events.

## Calendar and activation events

Owned by #90.

| Event | Notes |
| --- | --- |
| `calendar_created` | Include `cadence`, `tracking_type`, `has_reminder_enabled`, `has_backfilled_history`, `is_first_calendar`. |
| `calendar_archived` | Include `source`, `cadence`, `tracking_type`. Allowed sources: `drag_action`, `edit_calendar`, `unknown`. |
| `calendar_unarchived` | Include `source`, `cadence`, `tracking_type`. Allowed sources: `drag_action`, `edit_calendar`, `unknown`. |
| `activation_completed` | First meaningful activation once per install/user identity. Include `activation_source`. Allowed sources: `onboarding_first_dot`, `calendar_checkin`. |
| `checkin_completed` | First transition from no progress to progress for a period. Include `cadence`, `tracking_type`, `period`, `source`. Allowed sources: `calendar`, `notification`, `quick_add_deeplink`, `edit_sheet`, `unknown`. |
| `first_checkin_completed` | First check-in once per install/user identity. |
| `checkin_removed` | Progress removed from a period. Include `cadence`, `tracking_type`, `period`, `source`. |
| `period_completed` | Binary/target period reaches completion criteria. Counter calendars do not emit this in v1. Include `cadence`, `tracking_type`, `period`, `source`. |
| `period_uncompleted` | Completed period becomes incomplete. Include `cadence`, `tracking_type`, `period`, `source`. |

Allowed check-in `source` values: `calendar`, `notification`, `quick_add_deeplink`, `edit_sheet`, `unknown`.

Allowed activation `activation_source` values: `onboarding_first_dot`, `calendar_checkin`.

## Feature and reflective events

Owned by #91.

| Event | Notes |
| --- | --- |
| `mood_logged` | Include `has_note`. Do not send mood value or note text. |
| `mood_tracking_enabled_changed` | Include `enabled`. |
| `recap_view_enabled_changed` | Include `enabled`. |
| `milestone_celebrations_enabled_changed` | Include `enabled`. |
| `streak_milestone_celebrations_enabled_changed` | Include `enabled`. |
| `showed_up_milestone_celebrations_enabled_changed` | Include `enabled`. |
| `recap_milestone_celebrations_enabled_changed` | Include `enabled`. |
| `recap_view_viewed` | Recap View is actually viewed. |
| `calendars_overview_viewed` | Calendars overview sheet is opened/viewed. |

## Review events

| Event | Notes |
| --- | --- |
| `review_satisfaction_prompt_viewed` | Review satisfaction prompt is shown. Include coarse prompt context only. |
| `review_satisfaction_prompt_answered` | User answers the review satisfaction prompt. Include coarse answer metadata only. |
| `review_feedback_started` | User starts the private feedback flow. Do not include feedback text. |
| `review_feedback_submitted` | Private feedback submission succeeds. Do not include feedback text. |
| `review_feedback_submit_failed` | Private feedback submission fails. Include coarse failure category only. |
| `app_store_review_requested` | Native App Store review request is triggered. Include coarse trigger context only. |

## Paywall and sharing events

Owned by #92.

| Event | Notes |
| --- | --- |
| `paywall_prompt_considered` | Fires when the automatic upgrade prompter presents the paywall or skips a positive-event prompt. Include `paywall_trigger`, `result`, `paywall_prompt_kind`, and `total_positive_event_count`. Positive-event prompts also include `positive_event`. Results include `presented`, `not_enough_positive_events`, `cooldown`, `already_active`, and `not_eligible`. |
| `paywall_viewed` | Fires only when the paywall UI actually appears. Include `paywall_trigger` and `paywall_variant`. Automatic prompts also include `paywall_prompt_kind`, `prompt_count`, `total_positive_event_count`, and `positive_event` when relevant. |
| `paywall_package_selected` | Fires when the user changes the selected package. Include `paywall_trigger`, `paywall_variant`, `package_identifier`, `package_type`, `has_free_trial`, and `localized_price` when already available from StoreKit/RevenueCat. Automatic prompts also include prompt context when relevant. |
| `paywall_purchase_started` | Fires once per purchase attempt before calling RevenueCat. Include the same package properties as `paywall_package_selected`. |
| `paywall_purchase_succeeded` | Terminal event for a successful purchase attempt. Include the same package properties as `paywall_package_selected`. |
| `paywall_purchase_cancelled` | Terminal event for a user-cancelled purchase attempt. Include the same package properties as `paywall_package_selected` plus `is_user_cancelled`. |
| `paywall_purchase_failed` | Terminal event for a failed purchase attempt. Include the same package properties as `paywall_package_selected` plus coarse `error_category`. Never include raw error strings. |
| `paywall_restore_started` | Fires once per restore attempt before calling RevenueCat. Include `paywall_trigger` and `paywall_variant`. |
| `paywall_restore_succeeded` | Terminal event when restore finds active premium access. Include `paywall_trigger` and `paywall_variant`. |
| `paywall_restore_failed` | Terminal event when restore fails or finds no active subscription. Include `paywall_trigger`, `paywall_variant`, and coarse `error_category`. Never include raw error strings. |
| `paywall_closed` | Fires when the paywall closes. Include `paywall_trigger` and `paywall_variant`. |
| `share_sheet_viewed` | Fires when a share sheet is opened. Include `share_type`. Do not send stats, names, notes, or share content in v1. |

Allowed `paywall_trigger` values: `onboarding`, `calendar_limit`, `share_gate`, `stats_gate`, `notification_gate`, `settings_support`, `automatic_positive_event`, `automatic_timed`, `unknown`.

Allowed `paywall_prompt_kind` values: `positive_event`, `timed_random`.

Allowed `paywall_variant` values: `default`, `commitment_protection_v1`.

Allowed `package_type` values: `annual`, `monthly`, `weekly`, `unknown`.

Allowed paywall `error_category` values: `network`, `purchase_failed`, `restore_failed`, `unknown`.

Allowed `share_type` values: `calendar`, `recap`, `unknown`.

## Widget analytics

Widget analytics are a coarse proxy for adoption and usage. `widget_timeline_loaded` measures that WidgetKit asked the extension for a timeline entry in a non-preview context. It is not an impression count.

| Event | Fires when | Notes |
| --- | --- | --- |
| `widget_timeline_loaded` | A widget timeline is generated outside preview/snapshot flows. | Include `widget_kind`, `widget_family`, `has_calendar`, and coarse configuration fields where available. Allowed `widget_kind` values: `year`, `habits`, `streak`. Allowed `widget_family` values: `systemSmall`, `systemMedium`, `systemLarge`, `other`. |
| `widget_opened_app` | The app opens from a widget deep link. | Include `widget_kind`, `widget_action`, and `destination`. Do not include calendar IDs, calendar names, or user-entered text. |
| `widget_quick_add_performed` | The Habits widget AppIntent successfully runs. | Include `widget_kind`, `cadence`, `tracking_type`, and `result`. |
| `widget_quick_add_opened` | The iOS 16 quick-add fallback deep link opens the app. | Include `widget_kind`, `widget_action`, and `destination`. |

Allowed `widget_action` values: `open_app`, `open_calendar`, `quick_add`.

Allowed `destination` values: `home`, `calendar`, `quick_add`.

Allowed `result` values: `success`, `failed`, `invalid_calendar`.

Allowed `cadence` values: `daily`, `weekly`, `unknown`.

Allowed `tracking_type` values: `binary`, `counter`, `multiple_daily`, `unknown`.

`TrackingType.multipleDaily` is serialized as `multiple_daily` in analytics payloads. The Swift enum case name stays `multipleDaily`; only the analytics wire value is normalized.

Allowed `timeline_mode` values: `your365`, `calendarYear`, `unknown`.

## Explicitly out of scope for #79 v1

- Session replay
- Autocapture
- Acquisition source/campaign attribution
- Detailed onboarding step analytics (#87)
- Detailed paywall funnel analysis beyond prompt, impression, and lifecycle events
- Milestone celebration exposure/funnel
- Mood values
