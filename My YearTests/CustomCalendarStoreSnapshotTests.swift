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

    @Test func staleReloadCannotOverwriteNewerMutation() async throws {
        let plannedSnapshots = PlannedSnapshots([
            [],
            [makeCalendar(id: fixedID(1), name: "A")],
            [makeCalendar(id: fixedID(1), name: "A"), makeCalendar(id: fixedID(2), name: "B")],
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

    @Test func reloadWithoutMutationKeepsVersionStable() async throws {
        let store = makeStore()
        try await waitUntilLoaded(store)
        let startingVersion = store.snapshot.dataVersion

        store.loadCalendars(showLoadingIndicator: false)
        try await waitUntilLoaded(store, minimumVersion: startingVersion)

        #expect(store.snapshot.dataVersion == startingVersion)
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
