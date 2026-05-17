# Analytics Events

Yearlit analytics exists to answer product and marketing questions without collecting sensitive user-entered content.

## Privacy rules

Never send these values to analytics:

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
- `has_completed_first_checkin`
- `has_completed_first_period`

The same non-sensitive state may be set as PostHog person properties.

## Base lifecycle events

| Event | Fires when | Extra properties |
| --- | --- | --- |
| `app_opened` | App enters foreground/active state. | Standard properties only. |
| `onboarding_started` | Onboarding first appears once per install. | Standard properties only. |
| `onboarding_completed` | Onboarding is marked as seen. | Standard properties only. |

## Calendar and activation events

Owned by #90.

| Event | Notes |
| --- | --- |
| `calendar_created` | Include `cadence`, `tracking_type`, `has_reminder_enabled`, `has_backfilled_history`, `is_first_calendar`. |
| `calendar_archived` | Include `source`, `cadence`, `tracking_type`. |
| `calendar_unarchived` | Include `source`, `cadence`, `tracking_type`. |
| `checkin_completed` | First transition from no progress to progress for a period. Include `cadence`, `tracking_type`, `period`, `source`. |
| `first_checkin_completed` | First check-in once per install/user identity. |
| `checkin_removed` | Progress removed from a period. |
| `period_completed` | Binary/target period reaches completion criteria. Counter calendars do not emit this in v1. |
| `period_uncompleted` | Completed period becomes incomplete. |

Allowed check-in `source` values: `calendar`, `notification`, `quick_add_deeplink`, `edit_sheet`, `unknown`.

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

## Paywall and sharing events

Owned by #92.

| Event | Notes |
| --- | --- |
| `paywall_viewed` | Fires only when the paywall UI actually appears. Include `paywall_trigger` and `paywall_variant`. |
| `share_sheet_viewed` | Fires when a share sheet is opened. Include `share_type`. Do not send stats in v1. |

Allowed `paywall_trigger` values: `onboarding`, `calendar_limit`, `share_gate`, `stats_gate`, `notification_gate`, `settings_support`, `unknown`.

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

## Explicitly out of scope for #79 v1

- Session replay
- Autocapture
- Purchase/subscription lifecycle events in PostHog
- Acquisition source/campaign attribution
- Detailed onboarding step analytics (#87)
- Custom paywall/deep paywall funnel (#88)
- Milestone celebration exposure/funnel
- Mood values
