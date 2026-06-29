import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct AppleHealthEntryReplacementTests {
  @MainActor
  @Test func replaceAppleHealthEntriesDeduplicatesCanonicalDays() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 2)
    let calendar = CustomCalendar(
      id: id,
      name: "Walking",
      color: "qs-amber",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 8_000,
      unit: .steps,
      source: .appleHealthSteps
    )

    store.addCalendar(calendar)
    store.replaceAppleHealthEntries(
      calendarId: id,
      entries: [
        "stale-low": CalendarEntry(date: date, count: 7_000, completed: false),
        "stale-high": CalendarEntry(date: date, count: 9_000, completed: true)
      ],
      from: date,
      through: date
    )

    let context = ModelContext(container)
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let persisted = try #require(entries.first)

    #expect(entries.count == 1)
    #expect(persisted.dayKey == "2026-01-02")
    #expect(persisted.count == 9_000)
    #expect(persisted.completed)
  }

  @MainActor
  private func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
      for: HabitCalendarEntity.self,
      CalendarEntryEntity.self,
      DayValuationEntity.self,
      HabitStackEntity.self,
      HabitStackStepEntity.self,
      configurations: configuration
    )
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .gmt
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }
}
