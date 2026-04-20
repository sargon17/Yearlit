import Foundation
@testable import SharedModels
import SwiftData
import Testing

struct LegacyDataMigrationTests {
    @Test func migratesLegacyDataOnceAndSkipsSecondImport() throws {
        let fixture = makeDefaultsFixture()
        defer { tearDownDefaultsFixture(fixture) }

        let container = makeContainer()
        let calendar = makeCalendar(name: "Legacy")
        let encodedCalendars = try #require(try? JSONEncoder().encode([calendar]))
        fixture.defaults.set(encodedCalendars, forKey: LegacyPersistenceKeys.calendarsKey)

        LegacyDataMigrator.migrateIfNeeded(container: container, defaults: fixture.defaults)
        LegacyDataMigrator.migrateIfNeeded(container: container, defaults: fixture.defaults)

        #expect(fetchCalendarCount(in: container) == 1)
        #expect(fixture.defaults.bool(forKey: LegacyPersistenceKeys.migrationFlagKey))
    }

    @Test func doesNotReimportLegacyDataWhenMigratedUserHasEmptySwiftDataStore() throws {
        let fixture = makeDefaultsFixture()
        defer { tearDownDefaultsFixture(fixture) }

        let container = makeContainer()
        let calendar = makeCalendar(name: "Stale Legacy")
        let encodedCalendars = try #require(try? JSONEncoder().encode([calendar]))
        fixture.defaults.set(encodedCalendars, forKey: LegacyPersistenceKeys.calendarsKey)
        fixture.defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)

        LegacyDataMigrator.migrateIfNeeded(container: container, defaults: fixture.defaults)

        #expect(fetchCalendarCount(in: container) == 0)
    }

    @Test func runsDayKeyMigrationEvenWhenLegacyImportIsSkipped() throws {
        let fixture = makeDefaultsFixture()
        defer { tearDownDefaultsFixture(fixture) }

        let container = makeContainer()
        let context = ModelContext(container)
        context.autosaveEnabled = false

        let date = try #require(makeDate(year: 2026, month: 1, day: 12, hour: 18, minute: 45))
        context.insert(
            DayValuationEntity(
                dayKey: "outdated-key",
                timestamp: date,
                moodRawValue: DayMood.good.rawValue
            )
        )
        try context.save()

        fixture.defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)

        LegacyDataMigrator.migrateIfNeeded(container: container, defaults: fixture.defaults)

        let migratedValuation = try #require(fetchValuations(in: container).first)
        #expect(migratedValuation.dayKey == DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date)))
        #expect(migratedValuation.timestamp == LocalDayCalendar.startOfDay(for: date))
        #expect(fixture.defaults.bool(forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey))
    }

    private func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: HabitCalendarEntity.self,
            CalendarEntryEntity.self,
            DayValuationEntity.self,
            HabitStackEntity.self,
            HabitStackStepEntity.self,
            configurations: configuration
        )
    }

    private func fetchCalendarCount(in container: ModelContainer) -> Int {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return (try? context.fetchCount(FetchDescriptor<HabitCalendarEntity>())) ?? 0
    }

    private func fetchValuations(in container: ModelContainer) -> [DayValuationEntity] {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return (try? context.fetch(FetchDescriptor<DayValuationEntity>())) ?? []
    }

    private func makeDefaultsFixture() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "LegacyDataMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }

    private func tearDownDefaultsFixture(_ fixture: (suiteName: String, defaults: UserDefaults)) {
        fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
    }

    private func makeCalendar(name: String) -> CustomCalendar {
        CustomCalendar(
            name: name,
            color: "qs-emerald",
            trackingType: .binary,
            dailyTarget: 1
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
    }
}
