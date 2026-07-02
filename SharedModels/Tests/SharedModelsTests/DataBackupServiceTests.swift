import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct DataBackupServiceTests {
  @MainActor
  @Test func protectiveBackupStoresRestorableMetadata() throws {
    let harness = try Harness()
    try harness.seedSampleData()

    let backup = try harness.service.createProtectiveBackup(reason: .beforeBulkChange)
    let backups = harness.service.availableBackups()

    #expect(backups == [backup])
    #expect(backup.reason == .beforeBulkChange)
    #expect(backup.counts.calendars == 1)
    #expect(backup.counts.checkIns == 1)
    #expect(backup.counts.moodEntries == 1)
    #expect(backup.counts.journalNotes == 1)
    #expect(backup.counts.habitStacks == 1)
  }

  @MainActor
  @Test func automaticBackupRunsOncePerDayOnlyWhenDataChanged() throws {
    let harness = try Harness()
    try harness.seedSampleData()

    let first = try harness.service.createAutomaticBackupIfNeeded()
    let second = try harness.service.createAutomaticBackupIfNeeded()

    #expect(first != nil)
    #expect(second == nil)

    harness.now = Self.makeDate(year: 2026, month: 1, day: 2)
    let unchangedNextDay = try harness.service.createAutomaticBackupIfNeeded()
    #expect(unchangedNextDay == nil)

    try harness.insertCalendar(name: "Second")
    let changedNextDay = try harness.service.createAutomaticBackupIfNeeded()
    #expect(changedNextDay != nil)
  }

  @MainActor
  @Test func automaticBackupIsRecreatedWhenAutomaticHistoryIsMissing() throws {
    let harness = try Harness()
    try harness.seedSampleData()

    let first = try #require(try harness.service.createAutomaticBackupIfNeeded())
    try FileManager.default.removeItem(at: harness.directoryURL.appendingPathComponent(first.fileName))

    let recreated = try harness.service.createAutomaticBackupIfNeeded()

    #expect(recreated?.reason == .automatic)
    #expect(harness.service.availableBackups().filter { $0.reason == .automatic }.count == 1)
  }

  @MainActor
  @Test func restoreFullyReplacesDurableData() throws {
    let harness = try Harness()
    try harness.seedSampleData()
    let backup = try harness.service.createProtectiveBackup(reason: .automatic)

    try harness.deleteAllData()
    try harness.insertCalendar(name: "Replacement")

    try harness.service.restoreBackup(id: backup.id)

    let context = ModelContext(harness.container)
    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let valuations = try context.fetch(FetchDescriptor<DayValuationEntity>())
    let stacks = try context.fetch(FetchDescriptor<HabitStackEntity>())
    let steps = try context.fetch(FetchDescriptor<HabitStackStepEntity>())

    #expect(calendars.map(\.name) == ["Original"])
    #expect(entries.count == 1)
    #expect(valuations.count == 1)
    #expect(stacks.map(\.name) == ["Morning"])
    #expect(steps.map(\.title) == ["Stretch"])
  }

  @MainActor
  @Test func retentionCapsProtectiveBackupsWithoutDeletingAutomaticHistory() throws {
    let harness = try Harness()
    try harness.seedSampleData()

    for day in 1 ... 3 {
      harness.now = Self.makeDate(year: 2026, month: 1, day: day)
      try harness.insertCalendar(name: "Automatic \(day)")
      _ = try harness.service.createAutomaticBackupIfNeeded()
    }

    for index in 0 ..< 25 {
      harness.now = Self.makeDate(year: 2026, month: 1, day: 4).addingTimeInterval(TimeInterval(index))
      _ = try harness.service.createProtectiveBackup(reason: .beforeBulkChange)
    }

    let backups = harness.service.availableBackups()
    #expect(backups.filter { $0.reason == .automatic }.count == 3)
    #expect(backups.filter { $0.reason == .beforeBulkChange }.count == 20)
  }

  @MainActor
  @Test func invalidFingerprintIsHiddenFromRestoreList() throws {
    let harness = try Harness()
    try harness.seedSampleData()
    let backup = try harness.service.createProtectiveBackup(reason: .automatic)
    let url = harness.directoryURL.appendingPathComponent(backup.fileName)
    var json = try String(contentsOf: url, encoding: .utf8)
    json = json.replacingOccurrences(of: "\"fingerprint\" : \"\(backup.fingerprint)\"", with: "\"fingerprint\" : \"bad\"")
    try json.write(to: url, atomically: true, encoding: .utf8)

    #expect(harness.service.availableBackups().isEmpty)
  }

  @MainActor
  private final class Harness {
    let container: ModelContainer
    let directoryURL: URL
    let defaults: UserDefaults
    var now = makeDate(year: 2026, month: 1, day: 1)

    var service: DataBackupService {
      DataBackupService(
        container: container,
        directoryURL: directoryURL,
        defaults: defaults,
        now: { self.now }
      )
    }

    init() throws {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      container = try ModelContainer(
        for: HabitCalendarEntity.self,
        CalendarEntryEntity.self,
        DayValuationEntity.self,
        HabitStackEntity.self,
        HabitStackStepEntity.self,
        configurations: configuration
      )
      directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("DataBackups", isDirectory: true)
      let suiteName = "DataBackupServiceTests-\(UUID().uuidString)"
      defaults = UserDefaults(suiteName: suiteName)!
      defaults.removePersistentDomain(forName: suiteName)
    }

    func seedSampleData() throws {
      try insertCalendar(name: "Original")
      let context = ModelContext(container)
      context.autosaveEnabled = false
      let valuation = DayValuation(date: Self.makeDate(year: 2026, month: 1, day: 1), mood: .good, note: "Good day")
      context.insert(
        DayValuationEntity(
          dayKey: valuation.id,
          timestamp: valuation.timestamp,
          moodRawValue: valuation.mood.rawValue,
          note: valuation.note
        )
      )
      let stack = try HabitStack(
        name: "Morning",
        prompt: "Start",
        steps: [HabitStackStep(stackId: UUID(), title: "Stretch", order: 0)]
      )
      context.insert(HabitStackEntity.make(from: stack))
      for step in stack.steps {
        context.insert(HabitStackStepEntity.make(from: step, stackId: stack.id))
      }
      try context.save()
    }

    func insertCalendar(name: String) throws {
      let calendar = CustomCalendar(
        name: name,
        color: "qs-amber",
        cadence: .daily,
        trackingType: .binary,
        trackingStartedAt: Self.makeDate(year: 2026, month: 1, day: 1),
        entries: [
          "2026-01-01": CalendarEntry(date: Self.makeDate(year: 2026, month: 1, day: 1), count: 1, completed: true)
        ]
      )
      let context = ModelContext(container)
      context.autosaveEnabled = false
      context.insert(HabitCalendarEntity.make(from: calendar))
      for (dayKey, entry) in calendar.entries {
        context.insert(
          CalendarEntryEntity(
            compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendar.id, dayKey: dayKey),
            calendarId: calendar.id,
            dayKey: dayKey,
            date: entry.date,
            count: entry.count,
            completed: entry.completed
          )
        )
      }
      try context.save()
    }

    func deleteAllData() throws {
      let context = ModelContext(container)
      context.autosaveEnabled = false
      for entity in try context.fetch(FetchDescriptor<HabitCalendarEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<CalendarEntryEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<DayValuationEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<HabitStackEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<HabitStackStepEntity>()) { context.delete(entity) }
      try context.save()
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
      DataBackupServiceTests.makeDate(year: year, month: month, day: day)
    }
  }

  private static func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .gmt
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }
}
