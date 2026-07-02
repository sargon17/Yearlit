import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct AppleHealthCalendarModelTests {
  @Test func customCalendarDecodesMissingSourceAsManual() throws {
    let json = """
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "name": "Walking",
        "color": "qs-amber",
        "cadence": "daily",
        "trackingType": "multipleDaily",
        "trackingStartedAt": 725846400,
        "dailyTarget": 8000,
        "order": 0,
        "isArchived": false,
        "recurringReminderEnabled": false,
        "notificationPrivacyMode": "full",
        "suppressWhenCompleted": true,
        "additionalReminderTimes": [],
        "streakProtectionEnabled": true,
        "streakProtectionThreshold": 5,
        "entries": {}
      }
      """

    let calendar = try JSONDecoder().decode(CustomCalendar.self, from: #require(json.data(using: .utf8)))

    #expect(calendar.source == .manual)
  }

  @Test func appleHealthMetricMapperCreatesTargetEntries() {
    let belowTarget = makeDate(year: 2026, month: 1, day: 2)
    let aboveTarget = makeDate(year: 2026, month: 1, day: 3)

    let entries = AppleHealthMetricEntryMapper.entries(
      from: [
        belowTarget: 7_999,
        aboveTarget: 8_001,
        makeDate(year: 2026, month: 1, day: 4): 0
      ],
      target: 8_000
    )

    #expect(entries["2026-01-02"]?.count == 7_999)
    #expect(entries["2026-01-02"]?.completed == false)
    #expect(entries["2026-01-03"]?.count == 8_001)
    #expect(entries["2026-01-03"]?.completed == true)
    #expect(entries["2026-01-04"] == nil)
  }

  @Test func appleHealthMetricResolvesSourceAndDefaults() {
    #expect(AppleHealthMetric(source: .manual) == nil)
    #expect(AppleHealthMetric(source: .appleHealthSteps) == .steps)
    #expect(AppleHealthMetric(source: .appleHealthActiveEnergy) == .activeEnergy)
    #expect(AppleHealthMetric(source: .appleHealthExerciseMinutes) == .exerciseMinutes)
    #expect(AppleHealthMetric(source: .appleHealthWalkingRunningDistance) == .walkingRunningDistance)
    #expect(AppleHealthMetric(source: .appleHealthFlightsClimbed) == .flightsClimbed)
    #expect(AppleHealthMetric.activeEnergy.source == .appleHealthActiveEnergy)
    #expect(AppleHealthMetric.activeEnergy.defaultTarget == 300)
    #expect(AppleHealthMetric.activeEnergy.unit == .calories)
  }

  @Test func targetRecomputeUpdatesCompletionWithoutChangingCounts() {
    let calendar = CustomCalendar(
      name: "Walking",
      color: "qs-amber",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 8_000,
      entries: [
        "2026-01-02": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 2),
          count: 7_000,
          completed: false
        ),
        "2026-01-03": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 3),
          count: 9_000,
          completed: true
        )
      ],
      unit: .steps,
      source: .appleHealthSteps
    )

    let updated = calendar.recomputingCompletionForTarget(7_500)

    #expect(updated.dailyTarget == 7_500)
    #expect(updated.entries["2026-01-02"]?.count == 7_000)
    #expect(updated.entries["2026-01-02"]?.completed == false)
    #expect(updated.entries["2026-01-03"]?.count == 9_000)
    #expect(updated.entries["2026-01-03"]?.completed == true)
  }

  @MainActor
  @Test func fetchCalendarsPrefersActiveMetadataWhenDuplicateRowsExist() throws {
    let container = try makeContainer()
    let id = UUID()
    let context = ModelContext(container)
    context.insert(
      HabitCalendarEntity(
        id: id,
        name: "Archived duplicate",
        color: "qs-orange",
        trackingTypeRawValue: TrackingType.binary.rawValue,
        dailyTarget: 1,
        trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
        isArchived: true,
        order: 0
      )
    )
    context.insert(
      HabitCalendarEntity(
        id: id,
        name: "Active duplicate",
        color: "qs-orange",
        trackingTypeRawValue: TrackingType.binary.rawValue,
        dailyTarget: 1,
        trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
        isArchived: false,
        order: 10
      )
    )
    context.insert(
      CalendarEntryEntity(
        compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: id, dayKey: "2026-01-02"),
        calendarId: id,
        dayKey: "2026-01-02",
        date: makeDate(year: 2026, month: 1, day: 2),
        count: 1,
        completed: true
      )
    )
    try context.save()

    let calendars = CustomCalendarStore.fetchCalendarsSnapshot(container: container)
    let calendar = try #require(calendars.first)

    #expect(calendars.count == 1)
    #expect(calendar.name == "Active duplicate")
    #expect(calendar.isArchived == false)
    #expect(calendar.entries.count == 1)
  }

  @MainActor
  @Test func migrationRepairV2RestoresActiveMetadataFromLegacyPayload() throws {
    let container = try makeContainer()
    let (defaultsSuiteName, defaults) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

    let id = UUID()
    let legacyCalendar = CustomCalendar(
      id: id,
      name: "No energy drinks",
      color: "qs-orange",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "2026-01-02": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 2),
          count: 1,
          completed: true
        )
      ],
      isArchived: false
    )
    defaults.set(try JSONEncoder().encode([legacyCalendar]), forKey: LegacyPersistenceKeys.calendarsKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey)

    let context = ModelContext(container)
    context.insert(
      HabitCalendarEntity(
        id: id,
        name: "No energy drinks",
        color: "qs-orange",
        trackingTypeRawValue: TrackingType.binary.rawValue,
        dailyTarget: 1,
        trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
        isArchived: true,
        order: 0
      )
    )
    try context.save()

    LegacyDataMigrator.migrateIfNeeded(container: container, defaults: defaults)

    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let repairedCalendar = try #require(calendars.first)

    #expect(defaults.bool(forKey: LegacyPersistenceKeys.legacyCalendarRepairV2FlagKey))
    #expect(repairedCalendar.isArchived == false)
  }

  @MainActor
  @Test func migrationRepairsMissingSwiftDataEntriesFromLegacyPayload() throws {
    let container = try makeContainer()
    let (defaultsSuiteName, defaults) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

    let calendar = CustomCalendar(
      name: "No energy drinks",
      color: "qs-orange",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "2026-01-02": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 2),
          count: 1,
          completed: true
        )
      ]
    )
    defaults.set(try JSONEncoder().encode([calendar]), forKey: LegacyPersistenceKeys.calendarsKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey)

    let context = ModelContext(container)
    context.insert(HabitCalendarEntity.make(from: calendar))
    try context.save()

    LegacyDataMigrator.migrateIfNeeded(container: container, defaults: defaults)

    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())

    #expect(defaults.bool(forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey))
    #expect(entries.count == 1)
    #expect(entries.first?.dayKey == "2026-01-02")
  }

  @MainActor
  @Test func migrationRepairsMissingSwiftDataCalendarsFromLegacyPayload() throws {
    let container = try makeContainer()
    let (defaultsSuiteName, defaults) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }

    let calendar = CustomCalendar(
      name: "Reading",
      color: "qs-blue",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "2026-01-03": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 3),
          count: 1,
          completed: true
        )
      ]
    )
    defaults.set(try JSONEncoder().encode([calendar]), forKey: LegacyPersistenceKeys.calendarsKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
    defaults.set(true, forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey)

    LegacyDataMigrator.migrateIfNeeded(container: container, defaults: defaults)

    let context = ModelContext(container)
    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())

    #expect(defaults.bool(forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey))
    #expect(calendars.count == 1)
    #expect(calendars.first?.name == "Reading")
    #expect(entries.count == 1)
    #expect(entries.first?.dayKey == "2026-01-03")
  }

  @MainActor
  @Test func updateCalendarPreservesExistingManualEntriesWhenPayloadOmitsEntries() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let calendar = CustomCalendar(
      name: "No energy drinks",
      color: "qs-orange",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1,
      entries: [
        "2026-01-02": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 2),
          count: 1,
          completed: true
        ),
        "2026-01-03": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 3),
          count: 1,
          completed: true
        )
      ]
    )

    store.addCalendar(calendar)
    var metadataOnlyUpdate = calendar
    metadataOnlyUpdate.name = "No energy drinks edited"
    metadataOnlyUpdate.entries = [:]

    store.updateCalendar(metadataOnlyUpdate)

    let context = ModelContext(container)
    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let updatedCalendar = try #require(calendars.first)

    #expect(updatedCalendar.name == "No energy drinks edited")
    #expect(entries.count == 2)
    #expect(Set(entries.map(\.dayKey)) == ["2026-01-02", "2026-01-03"])
  }

  @MainActor
  @Test func updateCalendarPreservesAppleHealthMetricUnit() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let calendar = CustomCalendar(
      name: "Active Energy",
      color: "qs-orange",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 300,
      unit: .calories,
      source: .appleHealthActiveEnergy
    )

    store.addCalendar(calendar)
    var maliciousUpdate = calendar
    maliciousUpdate.source = .manual
    maliciousUpdate.unit = .steps
    maliciousUpdate.dailyTarget = 400

    store.updateCalendar(maliciousUpdate)

    let context = ModelContext(container)
    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let updatedCalendar = try #require(calendars.first)

    #expect(updatedCalendar.sourceRawValue == CalendarSource.appleHealthActiveEnergy.rawValue)
    #expect(updatedCalendar.unitRawValue == UnitOfMeasure.calories.rawValue)
    #expect(updatedCalendar.dailyTarget == 400)
  }

  @MainActor
  @Test func updateCalendarPreservesAppleHealthSourceAndEntries() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let persistedEntryDate = makeDate(year: 2026, month: 1, day: 2)
    let calendar = CustomCalendar(
      id: id,
      name: "Walking",
      color: "qs-amber",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 8_000,
      entries: [
        "2026-01-02": CalendarEntry(date: persistedEntryDate, count: 9_000, completed: true)
      ],
      unit: .steps,
      source: .appleHealthSteps
    )

    store.addCalendar(calendar)
    var maliciousUpdate = calendar
    maliciousUpdate.source = .manual
    maliciousUpdate.cadence = .weekly
    maliciousUpdate.trackingType = .binary
    maliciousUpdate.unit = nil
    maliciousUpdate.dailyTarget = 10_000
    maliciousUpdate.entries = [
      "2026-01-03": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 3), count: 1, completed: true)
    ]

    store.updateCalendar(maliciousUpdate)

    let context = ModelContext(container)
    let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let updatedCalendar = try #require(calendars.first)
    let updatedEntry = try #require(entries.first)

    #expect(updatedCalendar.sourceRawValue == CalendarSource.appleHealthSteps.rawValue)
    #expect(updatedCalendar.cadenceRawValue == CalendarCadence.daily.rawValue)
    #expect(updatedCalendar.trackingTypeRawValue == TrackingType.binary.rawValue)
    #expect(updatedCalendar.unitRawValue == UnitOfMeasure.steps.rawValue)
    #expect(updatedCalendar.dailyTarget == 10_000)
    #expect(entries.count == 1)
    #expect(updatedEntry.dayKey == "2026-01-02")
    #expect(updatedEntry.count == 9_000)
    #expect(updatedEntry.completed == false)
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .gmt
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }

  private func makeDefaults() -> (suiteName: String, defaults: UserDefaults) {
    let suiteName = "SharedModelsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (suiteName, defaults)
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
}
