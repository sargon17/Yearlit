import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct LegacyDataMigrationConcurrencyTests {
  @Test func appExtensionsDoNotRunMigration() {
    #expect(!LegacyDataMigrator.shouldRunMigration(in: URL(fileURLWithPath: "/App/Widget.appex")))
    #expect(LegacyDataMigrator.shouldRunMigration(in: URL(fileURLWithPath: "/App/Yearlit.app")))
  }

  @Test func concurrentMigrationImportsLegacyDataOnce() throws {
    let suiteName = "LegacyDataMigrationConcurrencyTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let container = try makeContainer()
    let calendar = CustomCalendar(
      name: "Legacy",
      color: "qs-emerald",
      trackingType: .binary,
      trackingStartedAt: Date(),
      dailyTarget: 1
    )
    defaults.set(try JSONEncoder().encode([calendar]), forKey: LegacyPersistenceKeys.calendarsKey)
    markFollowUpMigrationsComplete(in: defaults)

    DispatchQueue.concurrentPerform(iterations: 8) { _ in
      LegacyDataMigrator.migrateIfNeeded(container: container, defaults: defaults)
    }

    let context = ModelContext(container)
    let count = try context.fetchCount(FetchDescriptor<HabitCalendarEntity>())
    #expect(count == 1)
    #expect(defaults.bool(forKey: LegacyPersistenceKeys.migrationFlagKey))
  }

  @Test func pendingMigrationCreatesFreshBackupDespiteExistingFlag() throws {
    let suiteName = "LegacyDataMigrationBackupTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let container = try makeContainer()
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let service = DataBackupService(container: container, directoryURL: directory, defaults: defaults)
    _ = try service.createProtectiveBackup(reason: .beforeMigration)
    let context = ModelContext(container)
    context.insert(HabitCalendarEntity(
      name: "New data",
      color: "qs-blue",
      trackingTypeRawValue: TrackingType.binary.rawValue,
      dailyTarget: 1
    ))
    try context.save()
    defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.migrationBackupFlagKey)

    LegacyDataMigrator.migrateIfNeeded(
      container: container,
      defaults: defaults,
      backupDirectoryURL: directory
    )

    let migrationBackups = service.availableBackups().filter { $0.reason == .beforeMigration }
    #expect(migrationBackups.count == 2)
    #expect(Set(migrationBackups.map(\.fingerprint)).count == 2)
  }

  private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
      for: HabitCalendarEntity.self,
      CalendarEntryEntity.self,
      DayValuationEntity.self,
      HabitStackEntity.self,
      HabitStackStepEntity.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }

  private func markFollowUpMigrationsComplete(in defaults: UserDefaults) {
    defaults.set(true, forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.trackingStartedAtBackfillMigrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.trackingStartedAtRepairMigrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.legacyCalendarRepairV2FlagKey)
  }
}
