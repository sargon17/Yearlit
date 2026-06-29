import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct LegacyOldCalendarMigrationTests {
  private struct OldCalendar: Codable {
    let id: UUID
    var name: String
    var color: String
    var trackingType: TrackingType
    var entries: [String: CalendarEntry]
  }

  @Test func oldLegacyCalendarWithoutTrackingStartUsesEarliestEntryBucket() throws {
    let fixture = makeDefaultsFixture()
    defer { tearDownDefaultsFixture(fixture) }

    let container = try makeContainer()
    let id = UUID()
    let staleEntryDate = try #require(makeDate(year: 2026, month: 6, day: 1, hour: 18, minute: 45))
    let earliestDate = try #require(makeDate(year: 2025, month: 6, day: 1, hour: 8, minute: 0))
    let latestDate = try #require(makeDate(year: 2026, month: 1, day: 15, hour: 8, minute: 0))
    let earliestKey = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: earliestDate))
    let latestKey = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: latestDate))
    let oldCalendar = OldCalendar(
      id: id,
      name: "Old Long Streak",
      color: "qs-emerald",
      trackingType: .binary,
      entries: [
        earliestKey: CalendarEntry(date: staleEntryDate, count: 1, completed: true),
        latestKey: CalendarEntry(date: staleEntryDate, count: 1, completed: true)
      ]
    )
    let encodedCalendars = try #require(try? JSONEncoder().encode([oldCalendar]))
    fixture.defaults.set(encodedCalendars, forKey: LegacyPersistenceKeys.calendarsKey)

    LegacyDataMigrator.migrateIfNeeded(container: container, defaults: fixture.defaults)

    let context = ModelContext(container)
    context.autosaveEnabled = false
    let migratedCalendar = try #require(context.fetch(FetchDescriptor<HabitCalendarEntity>()).first)

    #expect(migratedCalendar.trackingStartedAt == LocalDayCalendar.startOfDay(for: earliestDate))
  }

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

  private func makeDefaultsFixture() -> (suiteName: String, defaults: UserDefaults) {
    let suiteName = "LegacyOldCalendarMigrationTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (suiteName, defaults)
  }

  private func tearDownDefaultsFixture(_ fixture: (suiteName: String, defaults: UserDefaults)) {
    fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
  }

  private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
  }
}
