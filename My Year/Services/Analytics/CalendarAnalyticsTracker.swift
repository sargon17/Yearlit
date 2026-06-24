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

  init(analytics: Analytics = .shared, state: AnalyticsState = .shared) {
    self.analytics = analytics
    self.state = state
  }

  func trackCalendarCreated(calendar: CustomCalendar, isFirstCalendar: Bool) {
    analytics.track(.calendarCreated, properties: calendarProperties(calendar).merging([
      "has_reminder_enabled": .bool(calendar.recurringReminderEnabled),
      "has_backfilled_history": .bool(!calendar.entries.isEmpty),
      "is_first_calendar": .bool(isFirstCalendar)
    ]) { _, new in new })
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
    let transition = entryTransition(for: calendar, oldEntry: oldEntry, newEntry: newEntry)

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
  }

  private func calendarProperties(_ calendar: CustomCalendar) -> [String: AnalyticsPropertyValue] {
    [
      "cadence": .string(calendar.cadence.rawValue),
      "tracking_type": .string(calendar.trackingType.rawValue)
    ]
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

  private func entryTransition(
    for calendar: CustomCalendar,
    oldEntry: CalendarEntry?,
    newEntry: CalendarEntry?
  ) -> EntryTransition {
    let hadProgress = hasProgress(for: calendar, entry: oldEntry)
    let hasProgress = hasProgress(for: calendar, entry: newEntry)
    let wasComplete = isComplete(for: calendar, entry: oldEntry)
    let isComplete = isComplete(for: calendar, entry: newEntry)
    let period = calendar.cadence == .daily ? "day" : "week"

    return EntryTransition(
      checkinCompleted: !hadProgress && hasProgress,
      checkinRemoved: hadProgress && !hasProgress,
      periodCompleted: supportsPeriodCompletion(calendar: calendar) && !wasComplete && isComplete,
      periodUncompleted: supportsPeriodCompletion(calendar: calendar) && wasComplete && !isComplete,
      period: period
    )
  }

  private func supportsPeriodCompletion(calendar: CustomCalendar) -> Bool {
    calendar.trackingType != .counter
  }

  private func hasProgress(for calendar: CustomCalendar, entry: CalendarEntry?) -> Bool {
    guard let entry else { return false }
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter, .multipleDaily:
      return entry.count >= 1
    }
  }

  private func isComplete(for calendar: CustomCalendar, entry: CalendarEntry?) -> Bool {
    guard let entry else { return false }
    switch calendar.trackingType {
    case .binary, .multipleDaily:
      return entry.completed
    case .counter:
      return false
    }
  }

  private struct EntryTransition {
    let checkinCompleted: Bool
    let checkinRemoved: Bool
    let periodCompleted: Bool
    let periodUncompleted: Bool
    let period: String
  }
}
