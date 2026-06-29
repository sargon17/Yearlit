import Foundation
import Testing

@testable import SharedModels

struct CustomCalendarEntryLookupTests {
  @Test func entryFindsDailyEntryWithStaleDictionaryKey() {
    let date = makeDate(year: 2026, month: 2, day: 4)
    let calendar = CustomCalendar(
      name: "Manual",
      color: "qs-blue",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "stale-key": CalendarEntry(date: date, count: 4, completed: true)
      ]
    )

    #expect(calendar.entry(for: date)?.count == 4)
  }

  @Test func entryKeepsBestDuplicateEntryForSameBucket() {
    let date = makeDate(year: 2026, month: 2, day: 4)
    let calendar = CustomCalendar(
      name: "Manual",
      color: "qs-blue",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "stale-low": CalendarEntry(date: date, count: 1, completed: true),
        "stale-high": CalendarEntry(date: date, count: 7, completed: true)
      ]
    )

    #expect(calendar.entry(for: date)?.count == 7)
  }

  @Test func entryFindsWeeklyEntryWithStaleDictionaryKey() {
    let date = makeDate(year: 2026, month: 2, day: 4)
    let weekStart = LocalDayCalendar.startOfWeek(for: date)
    let calendar = CustomCalendar(
      name: "Manual",
      color: "qs-blue",
      cadence: .weekly,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "stale-week-key": CalendarEntry(date: weekStart, count: 3, completed: true)
      ]
    )

    #expect(calendar.entry(for: date)?.count == 3)
  }
}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .gmt
  return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}
