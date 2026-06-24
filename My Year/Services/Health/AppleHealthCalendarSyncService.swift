import Foundation
import SharedModels

@MainActor
struct AppleHealthCalendarSyncService {
  private let healthService = AppleHealthMetricService()
  private let store: CustomCalendarStore

  init() {
    store = .shared
  }

  init(store: CustomCalendarStore) {
    self.store = store
  }

  func syncAllConnectedCalendars() async {
    let calendarsByMetric = store.snapshot.calendars.reduce(
      into: [AppleHealthMetric: [CustomCalendar]]()
    ) { calendarsByMetric, calendar in
      guard let metric = calendar.appleHealthMetric, !calendar.isArchived else { return }
      calendarsByMetric[metric, default: []].append(calendar)
    }
    guard !calendarsByMetric.isEmpty else { return }

    do {
      try await healthService.requestAuthorization(for: Array(calendarsByMetric.keys))
    } catch {
      return
    }

    for (metric, calendars) in calendarsByMetric {
      guard let values = try? await healthService.currentYearValues(for: metric) else { continue }
      for calendar in calendars {
        sync(calendar: calendar, metricValues: values)
      }
    }
  }

  @discardableResult
  func sync(calendar: CustomCalendar) async throws -> AppleHealthCalendarSyncResult? {
    guard let metric = calendar.appleHealthMetric else { return nil }
    try await healthService.requestAuthorization(for: metric)
    let values = try await healthService.currentYearValues(for: metric)
    if let result = sync(calendar: calendar, metricValues: values) {
      return result
    }

    let start = Self.currentYearStartDate()
    let end = LocalDayCalendar.startOfDay(for: Date())
    guard !calendar.hasEntries(from: start, through: end) else { return nil }
    throw AppleHealthMetricServiceError.noReadableHealthData
  }

  @discardableResult
  private func sync(
    calendar: CustomCalendar,
    metricValues values: [Date: Int]
  ) -> AppleHealthCalendarSyncResult? {
    let start = Self.currentYearStartDate()
    let end = LocalDayCalendar.startOfDay(for: Date())
    let entries = AppleHealthMetricEntryMapper.entries(from: values, target: calendar.dailyTarget)
    guard !entries.isEmpty || !calendar.hasEntries(from: start, through: end) else { return nil }
    store.replaceAppleHealthEntries(calendarId: calendar.id, entries: entries, from: start, through: end)
    return AppleHealthCalendarSyncResult(calendar: calendar, entries: entries, start: start, end: end)
  }

  private static func currentYearStartDate() -> Date {
    let calendar = LocalDayCalendar.calendar
    let today = LocalDayCalendar.startOfDay(for: Date())
    let year = calendar.component(.year, from: today)
    return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? today
  }
}

struct AppleHealthCalendarSyncResult {
  let calendar: CustomCalendar
  let entries: [String: CalendarEntry]
  let start: Date
  let end: Date
}
