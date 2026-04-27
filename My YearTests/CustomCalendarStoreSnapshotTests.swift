import Combine
import Foundation
import SharedModels
import SwiftData
import Testing

@MainActor
struct CustomCalendarStoreSnapshotTests {
  @Test func addEntryPublishesFreshCalendarsWithFreshVersion() async throws {
    let store = makeStore()
    try await waitUntilLoaded(store)

    let calendar = makeCalendar(name: "Store Snapshot")
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { snapshot in
      snapshot.calendars.contains(where: { $0.id == calendar.id })
    }

    let startingVersion = store.snapshot.dataVersion
    let recorder = SnapshotRecorder(store: store)
    recorder.start()

    let entry = CalendarEntry(date: makeDate(year: 2026, month: 1, day: 3), count: 1, completed: true)
    store.addEntry(calendarId: calendar.id, entry: entry)

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 1) { snapshot in
      snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entry.date)?.count == 1
    }
    let snapshots = recorder.stop()

    #expect(
      !snapshots.contains { snapshot in
        snapshot.dataVersion >= startingVersion + 1
          && snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entry.date)?.count != 1
      }
    )
    #expect(store.snapshot.dataVersion == startingVersion + 1)
    #expect(store.snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entry.date)?.count == 1)
  }

  @Test func quickLogBinaryPublishesWithoutReloadingAllCalendars() async throws {
    let loader = CountingFetchCalendarsLoader()
    let store = makeStore(fetchCalendarsLoader: loader.loader)
    try await waitUntilLoaded(store)

    let calendar = makeCalendar(name: "Binary")
    let unrelated = makeCalendar(name: "Unrelated")
    store.addCalendar(calendar)
    store.addCalendar(unrelated)
    try await waitUntilLoaded(store) { $0.calendars.count == 2 }
    loader.reset()

    let startingVersion = store.snapshot.dataVersion
    let date = makeDate(year: 2026, month: 1, day: 4)
    store.quickLogEntry(calendarId: calendar.id, date: date)

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 1) { snapshot in
      snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: date)?.completed == true
    }

    #expect(loader.callCount == 0)
    #expect(store.snapshot.dataVersion == startingVersion + 1)
    #expect(store.snapshot.calendars.first(where: { $0.id == unrelated.id })?.entries.isEmpty == true)
  }

  @Test func quickLogBinarySecondTapRemovesEntryFromSnapshot() async throws {
    let loader = CountingFetchCalendarsLoader()
    let store = makeStore(fetchCalendarsLoader: loader.loader)
    try await waitUntilLoaded(store)

    let date = makeDate(year: 2026, month: 1, day: 5)
    var calendar = makeCalendar(name: "Binary")
    calendar.entries[DayKeyFormatter.shared.string(from: date)] = CalendarEntry(date: date, count: 1, completed: true)
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { $0.calendars.first(where: { $0.id == calendar.id })?.entry(for: date) != nil }
    loader.reset()

    let startingVersion = store.snapshot.dataVersion
    store.quickLogEntry(calendarId: calendar.id, date: date)

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 1) { snapshot in
      snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: date) == nil
    }

    #expect(loader.callCount == 0)
    #expect(store.snapshot.dataVersion == startingVersion + 1)
  }

  @Test func deleteEntryRemovesOnlyAffectedEntry() async throws {
    try await assertEntryRemovalMutation(removal: { store, calendar, date in
      store.deleteEntry(calendarId: calendar.id, date: date)
    })
  }

  @Test func clearEntriesClearsOnlyAffectedCalendarEntries() async throws {
    try await assertEntryRemovalMutation(removal: { store, calendar, _ in
      store.clearEntries(calendarId: calendar.id)
    })
  }

  @Test func staleReloadCannotOverwriteNewerMutation() async throws {
    let plannedSnapshots = PlannedSnapshots(
      [
        [],
        [makeCalendar(id: fixedID(1), name: "A")],
        [makeCalendar(id: fixedID(1), name: "A"), makeCalendar(id: fixedID(2), name: "B")]
      ], delays: [0, 300_000_000, 20_000_000])

    let store = makeStore(fetchCalendarsLoader: plannedSnapshots.loader)
    try await waitUntilLoaded(store)
    let startingVersion = store.snapshot.dataVersion
    let recorder = SnapshotRecorder(store: store)
    recorder.start()

    store.addCalendar(makeCalendar(id: fixedID(1), name: "A"))
    store.addCalendar(makeCalendar(id: fixedID(2), name: "B"))

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 2) { snapshot in
      snapshot.calendars.map(\.name).sorted() == ["A", "B"]
    }
    let snapshots = recorder.stop()

    #expect(
      !snapshots.contains { snapshot in
        snapshot.dataVersion >= startingVersion + 2 && snapshot.calendars.map(\.name).sorted() != ["A", "B"]
      }
    )
    #expect(store.snapshot.dataVersion == startingVersion + 2)
    #expect(store.snapshot.calendars.map(\.name).sorted() == ["A", "B"])
  }

  @Test func inFlightReloadCannotOverwriteEntryMutationSnapshot() async throws {
    let loader = ControlledStaleEntryLoader()
    let store = makeStore(fetchCalendarsLoader: loader.loader)
    try await waitUntilLoaded(store)

    let calendar = makeCalendar(id: fixedID(1), name: "Entry Race")
    store.addCalendar(calendar)
    try await waitUntilLoaded(store) { snapshot in
      snapshot.calendars.contains(where: { $0.id == calendar.id })
    }

    let staleCalendars = store.snapshot.calendars
    let startingVersion = store.snapshot.dataVersion
    loader.returnDelayed(staleCalendars, delay: 300_000_000)

    let recorder = SnapshotRecorder(store: store)
    recorder.start()
    store.loadCalendars(showLoadingIndicator: false)

    try await Task.sleep(nanoseconds: 50_000_000)
    let entryDate = makeDate(year: 2026, month: 1, day: 6)
    store.addEntry(
      calendarId: calendar.id,
      entry: CalendarEntry(date: entryDate, count: 1, completed: true)
    )

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 1) { snapshot in
      snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entryDate) != nil
    }
    try await Task.sleep(nanoseconds: 400_000_000)
    let snapshots = recorder.stop()

    #expect(store.snapshot.dataVersion >= startingVersion + 1)
    #expect(store.snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entryDate) != nil)
    #expect(
      !snapshots.contains { snapshot in
        snapshot.dataVersion >= startingVersion + 1
          && snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: entryDate) == nil
      }
    )
  }

  @Test func reloadWithoutMutationKeepsVersionStable() async throws {
    let store = makeStore()
    try await waitUntilLoaded(store)
    let startingVersion = store.snapshot.dataVersion

    store.loadCalendars(showLoadingIndicator: false)
    try await waitUntilLoaded(store, minimumVersion: startingVersion)

    #expect(store.snapshot.dataVersion == startingVersion)
  }

  private func assertEntryRemovalMutation(
    removal: (CustomCalendarStore, CustomCalendar, Date) -> Void
  ) async throws {
    let loader = CountingFetchCalendarsLoader()
    let store = makeStore(fetchCalendarsLoader: loader.loader)
    try await waitUntilLoaded(store)

    let targetDate = makeDate(year: 2026, month: 1, day: 8)
    let unrelatedDate = makeDate(year: 2026, month: 1, day: 9)
    var calendar = makeCalendar(name: "Target")
    calendar.entries[DayKeyFormatter.shared.string(from: targetDate)] = CalendarEntry(
      date: targetDate,
      count: 1,
      completed: true
    )
    var unrelated = makeCalendar(name: "Unrelated")
    unrelated.entries[DayKeyFormatter.shared.string(from: unrelatedDate)] = CalendarEntry(
      date: unrelatedDate,
      count: 1,
      completed: true
    )
    store.addCalendar(calendar)
    store.addCalendar(unrelated)
    try await waitUntilLoaded(store) { $0.calendars.count == 2 }
    loader.reset()

    let startingVersion = store.snapshot.dataVersion
    removal(store, calendar, targetDate)

    try await waitUntilLoaded(store, minimumVersion: startingVersion + 1) { snapshot in
      snapshot.calendars.first(where: { $0.id == calendar.id })?.entry(for: targetDate) == nil
    }

    #expect(loader.callCount == 0)
    #expect(store.snapshot.dataVersion == startingVersion + 1)
    #expect(store.snapshot.calendars.first(where: { $0.id == unrelated.id })?.entry(for: unrelatedDate) != nil)
  }

  private func makeStore(
    fetchCalendarsLoader: @escaping @Sendable (ModelContainer) throws -> [CustomCalendar] = { container in
      CustomCalendarStore.fetchCalendarsSnapshot(container: container)
    }
  ) -> CustomCalendarStore {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
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
        fetchCalendars: fetchCalendarsLoader,
        runMigration: { _ in }
      )
    )
  }

  private func waitUntilLoaded(
    _ store: CustomCalendarStore,
    minimumVersion: Int = 0,
    until predicate: @escaping (CustomCalendarStoreSnapshot) -> Bool = { _ in true }
  ) async throws {
    let deadline = Date().addingTimeInterval(3)
    while Date() < deadline {
      let snapshot = store.snapshot
      if !snapshot.isLoading, snapshot.dataVersion >= minimumVersion, predicate(snapshot) {
        return
      }
      try await Task.sleep(nanoseconds: 20_000_000)
    }

    Issue.record("Store did not finish loading before timeout")
    throw CancellationError()
  }

  private func makeCalendar(id: UUID = UUID(), name: String) -> CustomCalendar {
    CustomCalendar(
      id: id,
      name: name,
      color: "qs-emerald",
      trackingType: .binary,
      dailyTarget: 1
    )
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }

  private func fixedID(_ value: UInt8) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", Int(value)))!
  }
}

@MainActor
private final class SnapshotRecorder {
  private let store: CustomCalendarStore
  private var snapshots: [CustomCalendarStoreSnapshot] = []
  private var cancellable: AnyCancellable?

  init(store: CustomCalendarStore) {
    self.store = store
  }

  func start() {
    snapshots = []
    cancellable = store.$snapshot.sink(receiveValue: { [weak self] snapshot in
      self?.snapshots.append(snapshot)
    })
  }

  func stop() -> [CustomCalendarStoreSnapshot] {
    cancellable?.cancel()
    cancellable = nil
    return snapshots
  }
}

private final class CountingFetchCalendarsLoader: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0

  var callCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return count
  }

  func reset() {
    lock.lock()
    count = 0
    lock.unlock()
  }

  var loader: @Sendable (ModelContainer) throws -> [CustomCalendar] {
    { [self] container in
      lock.lock()
      count += 1
      lock.unlock()
      return CustomCalendarStore.fetchCalendarsSnapshot(container: container)
    }
  }
}

private final class ControlledStaleEntryLoader: @unchecked Sendable {
  private let lock = NSLock()
  private var staleSnapshot: [CustomCalendar]?
  private var delay: UInt64 = 0

  func returnDelayed(_ snapshot: [CustomCalendar], delay: UInt64) {
    lock.lock()
    staleSnapshot = snapshot
    self.delay = delay
    lock.unlock()
  }

  var loader: @Sendable (ModelContainer) throws -> [CustomCalendar] {
    { [self] container in
      let plan = nextPlan()
      if let snapshot = plan.snapshot {
        if plan.delay > 0 {
          Thread.sleep(forTimeInterval: Double(plan.delay) / 1_000_000_000)
        }
        return snapshot
      }
      return CustomCalendarStore.fetchCalendarsSnapshot(container: container)
    }
  }

  private func nextPlan() -> (snapshot: [CustomCalendar]?, delay: UInt64) {
    lock.lock()
    defer { lock.unlock() }

    let snapshot = staleSnapshot
    staleSnapshot = nil
    return (snapshot, delay)
  }
}

private final class PlannedSnapshots: @unchecked Sendable {
  private let lock = NSLock()
  private var snapshots: [[CustomCalendar]]
  private var delays: [UInt64]

  init(_ snapshots: [[CustomCalendar]], delays: [UInt64]) {
    self.snapshots = snapshots
    self.delays = delays
  }

  var loader: @Sendable (ModelContainer) throws -> [CustomCalendar] {
    { [self] _ in
      let plan = nextPlan()
      if plan.delay > 0 {
        Thread.sleep(forTimeInterval: Double(plan.delay) / 1_000_000_000)
      }
      return plan.snapshot
    }
  }

  private func nextPlan() -> (snapshot: [CustomCalendar], delay: UInt64) {
    lock.lock()
    defer { lock.unlock() }

    let snapshot = snapshots.isEmpty ? [] : snapshots.removeFirst()
    let delay = delays.isEmpty ? 0 : delays.removeFirst()
    return (snapshot, delay)
  }
}
