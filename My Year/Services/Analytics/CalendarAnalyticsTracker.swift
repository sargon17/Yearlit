import Foundation
import SharedModels

enum CalendarAnalyticsSource: String {
  case calendar
  case notification
  case quickAddDeeplink = "quick_add_deeplink"
  case shortcut
  case editSheet = "edit_sheet"
  case unknown
}

enum CalendarArchiveAnalyticsSource: String {
  case dragAction = "drag_action"
  case editCalendar = "edit_calendar"
  case unknown
}

@MainActor
final class CalendarAnalyticsTracker {
  static let shared = CalendarAnalyticsTracker()

  private let analytics: Analytics
  private let state: AnalyticsState

  init(analytics: Analytics? = nil, state: AnalyticsState? = nil) {
    self.analytics = analytics ?? .shared
    self.state = state ?? .shared
  }

  func trackCalendarCreated(calendar: CustomCalendar, isFirstCalendar: Bool) {
    analytics.track(
      .calendarCreated,
      properties: calendarProperties(calendar).merging([
        "has_reminder_enabled": .bool(calendar.recurringReminderEnabled),
        "has_backfilled_history": .bool(!calendar.entries.isEmpty),
        "is_first_calendar": .bool(isFirstCalendar)
      ]) { _, new in new }
    )
  }

  func trackAppleHealthMetricSelected(_ metric: AppleHealthMetric, hasExistingCalendar: Bool) {
    analytics.track(
      .appleHealthMetricSelected,
      properties: appleHealthProperties(metric).merging([
        "has_existing_calendar": .bool(hasExistingCalendar)
      ]) { _, new in new }
    )
  }

  func trackAppleHealthPermissionResult(_ metric: AppleHealthMetric, didGrantAccess: Bool) {
    analytics.track(
      .appleHealthPermissionResult,
      properties: appleHealthProperties(metric).merging([
        "did_grant_access": .bool(didGrantAccess)
      ]) { _, new in new }
    )
  }

  func trackAppleHealthImportPreviewLoaded(
    metric: AppleHealthMetric,
    importedDays: Int,
    completedDays: Int,
    target: Int
  ) {
    analytics.track(
      .appleHealthImportPreviewLoaded,
      properties: appleHealthImportProperties(
        metric: metric,
        importedDays: importedDays,
        completedDays: completedDays,
        target: target
      )
    )
  }

  func trackAppleHealthCalendarCreated(
    calendar: CustomCalendar,
    metric: AppleHealthMetric,
    importedDays: Int,
    completedDays: Int
  ) {
    analytics.track(
      .appleHealthCalendarCreated,
      properties: calendarProperties(calendar).merging(
        appleHealthImportProperties(
          metric: metric,
          importedDays: importedDays,
          completedDays: completedDays,
          target: calendar.dailyTarget
        )
      ) { _, new in new }
    )
  }

  func trackArchiveStateChange(
    calendar: CustomCalendar,
    source: CalendarArchiveAnalyticsSource,
    isArchived: Bool
  ) {
    let event: AnalyticsEvent = isArchived ? .calendarArchived : .calendarUnarchived
    analytics.track(event, properties: archiveProperties(calendar, source: source))
  }

  func trackEntryMutationDeferred(
    calendar: CustomCalendar,
    oldEntry: CalendarEntry?,
    newEntry: CalendarEntry?,
    source: CalendarAnalyticsSource
  ) {
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 200_000_000)
      trackEntryMutation(
        calendar: calendar,
        oldEntry: oldEntry,
        newEntry: newEntry,
        source: source
      )
    }
  }

  func trackEntryMutation(
    calendar: CustomCalendar,
    oldEntry: CalendarEntry?,
    newEntry: CalendarEntry?,
    source: CalendarAnalyticsSource
  ) {
    let transition = CalendarEntryAnalyticsTransition(
      calendar: calendar,
      oldEntry: oldEntry,
      newEntry: newEntry
    )

    if transition.checkinCompleted {
      analytics.track(
        .checkinCompleted,
        properties: entryProperties(calendar, period: transition.period, source: source)
      )
      if !state.hasCompletedFirstCheckin {
        analytics.markFirstCheckinCompleted()
      }
    }

    if transition.checkinRemoved {
      analytics.track(
        .checkinRemoved,
        properties: entryProperties(calendar, period: transition.period, source: source)
      )
    }

    if transition.periodCompleted {
      analytics.track(
        .periodCompleted,
        properties: entryProperties(calendar, period: transition.period, source: source)
      )
      if !state.hasCompletedFirstPeriod {
        analytics.markFirstPeriodCompleted()
      }
    }

    if transition.periodUncompleted {
      analytics.track(
        .periodUncompleted,
        properties: entryProperties(calendar, period: transition.period, source: source)
      )
    }

    if transition.checkinCompleted || transition.periodCompleted {
      addPositiveEvent(.completedCheckIn)
    }
  }

  private func calendarProperties(_ calendar: CustomCalendar) -> [String: AnalyticsPropertyValue] {
    [
      "cadence": .string(calendar.cadence.rawValue),
      "tracking_type": .string(calendar.trackingType.rawValue),
      "calendar_source": .string(calendar.source.rawValue)
    ]
  }

  private func appleHealthProperties(_ metric: AppleHealthMetric) -> [String: AnalyticsPropertyValue] {
    [
      "calendar_source": .string(metric.source.rawValue),
      "apple_health_metric": .string(metric.rawValue)
    ]
  }

  private func appleHealthImportProperties(
    metric: AppleHealthMetric,
    importedDays: Int,
    completedDays: Int,
    target: Int
  ) -> [String: AnalyticsPropertyValue] {
    appleHealthProperties(metric).merging([
      "target": .int(target),
      "imported_days": .int(importedDays),
      "completed_days": .int(completedDays)
    ]) { _, new in new }
  }

  private func archiveProperties(
    _ calendar: CustomCalendar,
    source: CalendarArchiveAnalyticsSource
  ) -> [String: AnalyticsPropertyValue] {
    calendarProperties(calendar).merging([
      "source": .string(source.rawValue)
    ]) { _, new in new }
  }

  private func entryProperties(
    _ calendar: CustomCalendar,
    period: String,
    source: CalendarAnalyticsSource
  ) -> [String: AnalyticsPropertyValue] {
    calendarProperties(calendar).merging([
      "period": .string(period),
      "source": .string(source.rawValue)
    ]) { _, new in new }
  }

}
