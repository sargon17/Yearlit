import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct CustomCalendarStoreEntryTests {
  @Test func checkInEntryCompletesBinaryCalendarWithoutTogglingItOff() {
    let calendar = makeCalendar(trackingType: .binary)
    let date = makeDate(year: 2026, month: 1, day: 2)
    let firstEntry = calendar.checkInEntry(date: date, existingEntry: nil)
    let secondEntry = calendar.checkInEntry(date: date, existingEntry: firstEntry)

    #expect(firstEntry?.completed == true)
    #expect(firstEntry?.count == 1)
    #expect(secondEntry == nil)
  }

  @Test func checkInEntryUsesDefaultValueForCountingCalendars() {
    let calendar = makeCalendar(trackingType: .counter, defaultRecordValue: 3)
    let date = makeDate(year: 2026, month: 1, day: 2)
    let firstEntry = calendar.checkInEntry(date: date, existingEntry: nil)
    let secondEntry = calendar.checkInEntry(date: date, existingEntry: firstEntry)

    #expect(firstEntry?.count == 3)
    #expect(secondEntry?.count == 6)
  }

  @MainActor
  @Test func saveEntryMovesEntryBetweenBuckets() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let originalDate = makeDate(year: 2026, month: 1, day: 2)
    let movedDate = makeDate(year: 2026, month: 1, day: 5)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)
    store.addEntry(calendarId: id, entry: CalendarEntry(date: originalDate, count: 1, completed: true))
    store.saveEntry(
      calendarId: id,
      replacing: originalDate,
      with: CalendarEntry(date: movedDate, count: 3, completed: true)
    )

    let context = ModelContext(container)
    let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let persisted = try #require(entries.first)

    #expect(entries.count == 1)
    #expect(persisted.dayKey == "2026-01-05")
    #expect(persisted.count == 3)
  }

  @MainActor
  @Test func getEntryKeepsBestDuplicateRowForSameCompositeKey() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)
    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 1)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 6)
    try context.save()

    let entry = store.getEntry(calendarId: id, date: date)

    #expect(entry?.count == 6)
  }

  @MainActor
  @Test func getEntryFindsStaleCompositeKeyByCanonicalDate() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)
    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "stale-key", date: date, count: 4)
    try context.save()

    let entry = store.getEntry(calendarId: id, date: date)

    #expect(entry?.count == 4)
  }

  @MainActor
  @Test func addEntryDeletesDuplicateRowsForSameCompositeKey() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)
    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 1)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 2)
    try context.save()

    store.addEntry(calendarId: id, entry: CalendarEntry(date: date, count: 7, completed: true))

    let refreshedContext = ModelContext(container)
    let entries = try refreshedContext.fetch(FetchDescriptor<CalendarEntryEntity>())
    let persisted = try #require(entries.first)

    #expect(entries.count == 1)
    #expect(persisted.dayKey == "2026-01-03")
    #expect(persisted.count == 7)
  }

  @MainActor
  @Test func deleteEntryDeletesDuplicateRowsForSameCompositeKey() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)
    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 1)
    insertEntry(context: context, calendarId: id, dayKey: "2026-01-03", date: date, count: 2)
    try context.save()

    store.deleteEntry(calendarId: id, date: date)

    let refreshedContext = ModelContext(container)
    let entries = try refreshedContext.fetch(FetchDescriptor<CalendarEntryEntity>())

    #expect(entries.isEmpty)
  }

  @MainActor
  @Test func updateCalendarCanonicalizesExistingStaleEntryKeys() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let dayStart = LocalDayCalendar.startOfDay(for: date)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)

    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "stale-key", date: date, count: 1)
    try context.save()

    var updated = calendar
    updated.entries = [
      "another-stale-key": CalendarEntry(date: date, count: 3, completed: true)
    ]

    store.updateCalendar(updated)

    let refreshedContext = ModelContext(container)
    let entries = try refreshedContext.fetch(FetchDescriptor<CalendarEntryEntity>())
    let persisted = try #require(entries.first)

    #expect(entries.count == 1)
    #expect(persisted.dayKey == "2026-01-03")
    #expect(persisted.date == dayStart)
    #expect(persisted.count == 3)
  }

  @MainActor
  @Test func fetchCalendarsCanonicalizesExistingStaleEntryKeys() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    context.insert(
      HabitCalendarEntity(
        id: id,
        name: "Manual",
        color: "qs-emerald",
        cadenceRawValue: CalendarCadence.daily.rawValue,
        trackingTypeRawValue: TrackingType.counter.rawValue,
        dailyTarget: 1,
        trackingStartedAt: makeDate(year: 2026, month: 1, day: 1)
      )
    )
    insertEntry(context: context, calendarId: id, dayKey: "stale-key", date: date, count: 4)
    try context.save()

    let calendar = try #require(CustomCalendarStore.fetchCalendars(container: container).first)

    #expect(calendar.entries["stale-key"] == nil)
    #expect(calendar.entries["2026-01-03"]?.count == 4)
    #expect(calendar.entry(for: date)?.count == 4)
  }

  @MainActor
  @Test func fetchCalendarsKeepsHighestCountForDuplicateCanonicalEntryKeys() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    context.insert(
      HabitCalendarEntity(
        id: id,
        name: "Manual",
        color: "qs-emerald",
        cadenceRawValue: CalendarCadence.daily.rawValue,
        trackingTypeRawValue: TrackingType.counter.rawValue,
        dailyTarget: 1,
        trackingStartedAt: makeDate(year: 2026, month: 1, day: 1)
      )
    )
    insertEntry(context: context, calendarId: id, dayKey: "stale-low", date: date, count: 1)
    insertEntry(context: context, calendarId: id, dayKey: "stale-high", date: date, count: 5)
    try context.save()

    let calendar = try #require(CustomCalendarStore.fetchCalendars(container: container).first)

    #expect(calendar.entries.count == 1)
    #expect(calendar.entries["2026-01-03"]?.count == 5)
  }

  @MainActor
  @Test func updateCalendarDeletesDuplicateCanonicalEntriesAfterKeepingBestExistingRow() throws {
    let container = try makeContainer()
    let store = CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in [] },
        runMigration: { _ in }
      )
    )
    let id = UUID()
    let date = makeDate(year: 2026, month: 1, day: 3)
    let calendar = CustomCalendar(
      id: id,
      name: "Manual",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: .counter,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 1
    )

    store.addCalendar(calendar)

    let context = ModelContext(container)
    insertEntry(context: context, calendarId: id, dayKey: "stale-low", date: date, count: 1)
    insertEntry(context: context, calendarId: id, dayKey: "stale-high", date: date, count: 5)
    try context.save()

    var updated = calendar
    updated.entries = [
      "2026-01-03": CalendarEntry(date: date, count: 6, completed: true)
    ]

    store.updateCalendar(updated)

    let refreshedContext = ModelContext(container)
    let entries = try refreshedContext.fetch(FetchDescriptor<CalendarEntryEntity>())
    let persisted = try #require(entries.first)

    #expect(entries.count == 1)
    #expect(persisted.dayKey == "2026-01-03")
    #expect(persisted.count == 6)
  }

}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .gmt
  return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private func insertEntry(
  context: ModelContext,
  calendarId: UUID,
  dayKey: String,
  date: Date,
  count: Int
) {
  context.insert(
    CalendarEntryEntity(
      compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey),
      calendarId: calendarId,
      dayKey: dayKey,
      date: date,
      count: count,
      completed: true
    )
  )
}

private func makeCalendar(
  trackingType: TrackingType,
  defaultRecordValue: Int? = nil
) -> CustomCalendar {
  CustomCalendar(
    name: "Manual",
    color: "qs-emerald",
    cadence: .daily,
    trackingType: trackingType,
    trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
    dailyTarget: 5,
    defaultRecordValue: defaultRecordValue
  )
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
