@testable import My_Year
import Foundation
import SharedModels
import SwiftData
import Testing

@MainActor
struct CalendarShortcutServiceTests {
  @Test func selectableCalendarsExcludeArchivedAndAppleHealthCalendars() throws {
    let manual = makeCalendar(name: "Manual")
    let archived = makeCalendar(name: "Archived", isArchived: true)
    let health = makeCalendar(name: "Steps", source: .appleHealthSteps)

    let calendars = CalendarShortcutService.selectableCalendars(calendars: [manual, archived, health])

    #expect(calendars.map(\.id) == [manual.id])
  }

  @Test func checkInCompletesBinaryCalendarWithoutTogglingItOff() async throws {
    let store = try makeStore()
    let calendar = makeCalendar(name: "Binary")
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { $0.calendar(id: calendar.id) != nil }

    let date = makeDate(year: 2026, month: 6, day: 24)
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: nil,
      store: store,
      source: .shortcut
    )
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: nil,
      store: store,
      source: .shortcut
    )

    let entry = store.getEntry(calendarId: calendar.id, date: date)
    #expect(entry?.completed == true)
    #expect(entry?.count == 1)
  }

  @Test func checkInAddsExplicitValueToCounterCalendar() async throws {
    let store = try makeStore()
    let calendar = makeCalendar(name: "Pages", trackingType: .counter, defaultRecordValue: 3)
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { $0.calendar(id: calendar.id) != nil }

    let date = makeDate(year: 2026, month: 6, day: 24)
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: 4,
      store: store,
      source: .shortcut
    )
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: 2,
      store: store,
      source: .shortcut
    )

    let entry = store.getEntry(calendarId: calendar.id, date: date)
    #expect(entry?.count == 6)
    #expect(entry?.completed == true)
  }

  @Test func checkInUsesCalendarDefaultValueForMultipleDailyCalendar() async throws {
    let store = try makeStore()
    let calendar = makeCalendar(
      name: "Water",
      trackingType: .multipleDaily,
      dailyTarget: 5,
      defaultRecordValue: 2
    )
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { $0.calendar(id: calendar.id) != nil }

    let date = makeDate(year: 2026, month: 6, day: 24)
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: nil,
      store: store,
      source: .shortcut
    )
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: nil,
      store: store,
      source: .shortcut
    )
    _ = try CalendarShortcutService.checkIn(
      calendar: calendar,
      date: date,
      value: nil,
      store: store,
      source: .shortcut
    )

    let entry = store.getEntry(calendarId: calendar.id, date: date)
    #expect(entry?.count == 6)
    #expect(entry?.completed == true)
  }

  @Test func checkInRejectsInvalidValues() async throws {
    let store = try makeStore()
    let calendar = makeCalendar(name: "Pages", trackingType: .counter)
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { $0.calendar(id: calendar.id) != nil }

    #expect(throws: CalendarShortcutIntentError.invalidValue) {
      _ = try CalendarShortcutService.checkIn(
        calendar: calendar,
        date: Date(),
        value: 0,
        store: store,
        source: .shortcut
      )
    }
  }

  private func makeStore() throws -> CustomCalendarStore {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: HabitCalendarEntity.self,
      CalendarEntryEntity.self,
      DayValuationEntity.self,
      HabitStackEntity.self,
      HabitStackStepEntity.self,
      configurations: configuration
    )

    return CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { container in
          CustomCalendarStore.fetchCalendarsSnapshot(container: container)
        },
        runMigration: { _ in }
      )
    )
  }

  private func waitUntilLoaded(
    _ store: CustomCalendarStore,
    until predicate: @escaping (CustomCalendarStoreSnapshot) -> Bool = { _ in true }
  ) async throws {
    let deadline = Date().addingTimeInterval(3)
    while Date() < deadline {
      let snapshot = store.snapshot
      if !snapshot.isLoading, predicate(snapshot) {
        return
      }
      try await Task.sleep(nanoseconds: 20_000_000)
    }

    Issue.record("Store did not finish loading before timeout")
    throw CancellationError()
  }

  private func makeCalendar(
    name: String,
    trackingType: TrackingType = .binary,
    dailyTarget: Int = 1,
    defaultRecordValue: Int? = nil,
    isArchived: Bool = false,
    source: CalendarSource = .manual
  ) -> CustomCalendar {
    CustomCalendar(
      name: name,
      color: "qs-blue",
      trackingType: trackingType,
      trackingStartedAt: Date(),
      dailyTarget: dailyTarget,
      isArchived: isArchived,
      defaultRecordValue: defaultRecordValue,
      source: source
    )
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date {
    guard let date = DateComponents(
      calendar: Calendar(identifier: .gregorian),
      year: year,
      month: month,
      day: day
    ).date else {
      Issue.record("Could not create test date \(year)-\(month)-\(day)")
      return Date()
    }

    return date
  }
}
