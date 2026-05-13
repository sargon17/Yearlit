import Foundation
@testable import My_Year
import SharedModels
import Testing

struct OverviewDerivedSnapshotServiceTests {
    @Test func concurrentRequestsShareSingleComputation() async {
        let counter = LockedCounter()
        let cacheStore = CacheStore(defaults: makeDefaults())
        let service = OverviewDerivedSnapshotService(
            dependencies: .init(
                cacheStore: cacheStore,
                compute: { calendars, year, dates, today, currentPeriodReferenceDate in
                    counter.increment()
                    Thread.sleep(forTimeInterval: 0.1)
                    return computeOverviewDerivedSnapshot(
                        calendars: calendars,
                        year: year,
                        dates: dates,
                        todayLocal: today,
                        currentPeriodReferenceDate: currentPeriodReferenceDate
                    )
                }
            )
        )

        let snapshot = CustomCalendarStoreSnapshot(
            calendars: [makeCalendar()],
            isLoading: false,
            dataVersion: 42
        )
        let today = makeDate(year: 2026, month: 1, day: 4)

        async let first = service.snapshot(storeSnapshot: snapshot, year: 2026, today: today)
        async let second = service.snapshot(storeSnapshot: snapshot, year: 2026, today: today)

        let results = await [first, second]

        #expect(counter.value == 1)
        #expect(results.allSatisfy { $0 != nil })
        #expect(results[0]?.zByDay == results[1]?.zByDay)
    }

    @Test func repeatedRequestsHitMemoryCache() async {
        let counter = LockedCounter()
        let cacheStore = CacheStore(defaults: makeDefaults())
        let service = OverviewDerivedSnapshotService(
            dependencies: .init(
                cacheStore: cacheStore,
                compute: { calendars, year, dates, today, currentPeriodReferenceDate in
                    counter.increment()
                    return computeOverviewDerivedSnapshot(
                        calendars: calendars,
                        year: year,
                        dates: dates,
                        todayLocal: today,
                        currentPeriodReferenceDate: currentPeriodReferenceDate
                    )
                }
            )
        )

        let snapshot = CustomCalendarStoreSnapshot(
            calendars: [makeCalendar()],
            isLoading: false,
            dataVersion: 7
        )
        let today = makeDate(year: 2026, month: 1, day: 5)

        _ = await service.snapshot(storeSnapshot: snapshot, year: 2026, today: today)
        _ = await service.snapshot(storeSnapshot: snapshot, year: 2026, today: today)

        #expect(counter.value == 1)
    }

    @Test func diskCacheSkipsComputation() async {
        let counter = LockedCounter()
        let cacheStore = CacheStore(defaults: makeDefaults())
        let service = OverviewDerivedSnapshotService(
            dependencies: .init(
                cacheStore: cacheStore,
                compute: { calendars, year, dates, today, currentPeriodReferenceDate in
                    counter.increment()
                    return computeOverviewDerivedSnapshot(
                        calendars: calendars,
                        year: year,
                        dates: dates,
                        todayLocal: today,
                        currentPeriodReferenceDate: currentPeriodReferenceDate
                    )
                }
            )
        )

        let snapshot = CustomCalendarStoreSnapshot(
            calendars: [makeCalendar()],
            isLoading: false,
            dataVersion: 5
        )
        let today = makeDate(year: 2026, month: 1, day: 6)
        let input = makeOverviewDerivedInput(year: 2026, dataVersion: 5, today: today)
        let derived = computeOverviewDerivedSnapshot(
            calendars: snapshot.calendars,
            year: 2026,
            dates: getYearDatesArray(for: 2026),
            todayLocal: today,
            currentPeriodReferenceDate: makeDate(year: 2026, month: 1, day: 6)
        )
        cacheStore.saveDisk(makeOverviewDerivedCacheKey(input), value: derived)

        let loaded = await service.snapshot(storeSnapshot: snapshot, year: 2026, today: today)

        #expect(counter.value == 0)
        #expect(loaded?.zByDay == derived.zByDay)
    }

    private func makeCalendar() -> CustomCalendar {
        CustomCalendar(
            name: "Overview Service",
            color: "qs-emerald",
            trackingType: .counter,
            trackingStartedAt: Date(),
            dailyTarget: 1,
            entries: [
                dayKey(for: makeDate(year: 2026, month: 1, day: 3)): CalendarEntry(
                    date: makeDate(year: 2026, month: 1, day: 3),
                    count: 3,
                    completed: true
                ),
            ]
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "OverviewDerivedSnapshotServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var currentValue = 0

    func increment() {
        lock.lock()
        currentValue += 1
        lock.unlock()
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return currentValue
    }
}
