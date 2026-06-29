import Foundation
import SwiftData

@testable import SharedModels

extension LegacyDataMigrationTests {
  func makeContainer() throws -> ModelContainer {
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

  func fetchCalendarCount(in container: ModelContainer) -> Int {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return (try? context.fetchCount(FetchDescriptor<HabitCalendarEntity>())) ?? 0
  }

  func fetchValuations(in container: ModelContainer) -> [DayValuationEntity] {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return (try? context.fetch(FetchDescriptor<DayValuationEntity>())) ?? []
  }

  func fetchEntries(in container: ModelContainer) -> [CalendarEntryEntity] {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return (try? context.fetch(FetchDescriptor<CalendarEntryEntity>())) ?? []
  }

  func makeDefaultsFixture() -> (suiteName: String, defaults: UserDefaults) {
    let suiteName = "LegacyDataMigrationTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (suiteName, defaults)
  }

  func tearDownDefaultsFixture(_ fixture: (suiteName: String, defaults: UserDefaults)) {
    fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
  }

  func makeCalendar(name: String) -> CustomCalendar {
    CustomCalendar(
      name: name,
      color: "qs-emerald",
      trackingType: .binary,
      trackingStartedAt: Date(),
      dailyTarget: 1
    )
  }

  func encodeTrackingStartedAtBackup(_ values: [UUID: Date]) throws -> Data {
    struct Backup: Codable {
      let createdAt: Date
      let valuesByCalendarId: [String: Date]
    }

    let stringValues = values.reduce(into: [String: Date]()) { partialResult, item in
      partialResult[item.key.uuidString] = item.value
    }
    return try JSONEncoder().encode(Backup(createdAt: Date(), valuesByCalendarId: stringValues))
  }

  func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
  }
}
