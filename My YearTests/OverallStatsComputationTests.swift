import Foundation
@testable import My_Year
import SharedModels
import Testing

struct OverallStatsComputationTests {
    @Test func counterPercentilesAreComputedOncePerCalendarShape() {
        let binaryCalendar = makeCalendar(name: "Binary", trackingType: .binary, entries: [
            makeEntry(year: 2026, month: 1, day: 1, count: 1, completed: true),
        ])
        let counterCalendar = makeCalendar(name: "Counter", trackingType: .counter, entries: [
            makeEntry(year: 2026, month: 1, day: 1, count: 1, completed: true),
            makeEntry(year: 2026, month: 1, day: 2, count: 3, completed: true),
            makeEntry(year: 2026, month: 1, day: 3, count: 8, completed: true),
            makeEntry(year: 2026, month: 1, day: 4, count: 10, completed: true),
        ])

        let percentiles = counterPercentile75ByCalendar(calendars: [binaryCalendar, counterCalendar])

        #expect(percentiles[binaryCalendar.id] == 1.0)
        #expect(percentiles[counterCalendar.id] == 8.5)
    }

    @Test func overallStatsBundleUsesDayMeanZForRollingAverages() {
        let calendar = makeCalendar(name: "Counter", trackingType: .counter, entries: [
            makeEntry(year: 2026, month: 1, day: 1, count: 2, completed: true),
            makeEntry(year: 2026, month: 1, day: 2, count: 4, completed: true),
            makeEntry(year: 2026, month: 1, day: 3, count: 6, completed: true),
        ])
        let today = makeDate(year: 2026, month: 1, day: 3)

        let bundle = computeOverallStatsBundle(
            calendars: [calendar],
            year: 2026,
            todayLocal: today,
            currentPeriodReferenceDate: today
        )

        #expect(bundle.currentPeriodCount == 6)
        #expect(bundle.basic.totalCount == 12)
        #expect(bundle.averageProgressTrailingLongWindow > 0)
        #expect(bundle.averageProgressTrailingShortWindow > 0)
        #expect(bundle.completionRateTrailingLongWindow > 0)
    }

    @Test func computeStreaksHandlesSparseSuccessDays() {
        let calendar = Calendar(identifier: .gregorian)
        let today = makeDate(year: 2026, month: 1, day: 5)
        let successDays = Set([
            makeDate(year: 2026, month: 1, day: 1),
            makeDate(year: 2026, month: 1, day: 2),
            makeDate(year: 2026, month: 1, day: 4),
        ])

        let streaks = computeStreaks(cal: calendar, successDays: successDays, today: today)

        #expect(streaks.longest == 2)
        #expect(streaks.current == 1)
    }

    @Test func weeklySuccessDaysExpandAcrossTheWholeWeek() {
        let weeklyCalendar = CustomCalendar(
            name: "Weekly",
            color: "qs-emerald",
            cadence: .weekly,
            trackingType: .binary,
            dailyTarget: 1,
            entries: [
                dayKey(for: makeDate(year: 2026, month: 1, day: 5)): makeEntry(
                    year: 2026,
                    month: 1,
                    day: 5,
                    count: 1,
                    completed: true
                )
            ]
        )

        let successDays = buildAllTimeSuccessDays(
            cal: Calendar(identifier: .gregorian),
            todayLocal: makeDate(year: 2026, month: 1, day: 11),
            calendars: [weeklyCalendar]
        )

        #expect(successDays.count == 7)
    }

    @Test func bucketedEntriesCollapseDuplicateBucketsWithoutCrashing() {
        let duplicateBucketDate = makeDate(year: 2026, month: 1, day: 6)
        let weeklyCalendar = makeCalendar(
            name: "Weekly Counter",
            trackingType: .counter,
            entries: [
                CalendarEntry(date: makeDate(year: 2026, month: 1, day: 5), count: 2, completed: true),
                CalendarEntry(date: duplicateBucketDate, count: 5, completed: true),
            ],
            cadence: .weekly
        )

        let bucketedEntries = buildEntriesByCalendarByBucket(calendars: [weeklyCalendar])
        let storedEntry = bucketedEntries[weeklyCalendar.id]?[weeklyCalendar.bucketDate(for: duplicateBucketDate)]

        #expect(bucketedEntries[weeklyCalendar.id]?.count == 1)
        #expect(storedEntry?.count == 7)
    }

    @Test func currentPeriodCountUsesBucketedWeeklyEntries() {
        let weeklyCalendar = makeCalendar(
            name: "Weekly Counter",
            trackingType: .counter,
            entries: [
                CalendarEntry(date: makeDate(year: 2026, month: 1, day: 5), count: 4, completed: true),
            ],
            cadence: .weekly
        )

        let bundle = computeOverallStatsBundle(
            calendars: [weeklyCalendar],
            year: 2026,
            todayLocal: makeDate(year: 2026, month: 1, day: 8),
            currentPeriodReferenceDate: makeDate(year: 2026, month: 1, day: 8)
        )

        #expect(bundle.currentPeriodCount == 4)
    }

    @Test func calendarEntriesFingerprintChangesWhenEntryMovesWithSameCount() {
        let firstCalendar = makeCalendar(
            name: "Counter",
            trackingType: .counter,
            entries: [
                makeEntry(year: 2026, month: 1, day: 1, count: 1, completed: true)
            ]
        )
        let secondCalendar = makeCalendar(
            id: firstCalendar.id,
            name: "Counter",
            trackingType: .counter,
            entries: [
                makeEntry(year: 2026, month: 1, day: 2, count: 1, completed: true)
            ]
        )

        #expect(calendarEntriesFingerprint(firstCalendar) != calendarEntriesFingerprint(secondCalendar))
    }

    @Test func calendarEntriesFingerprintChangesWhenDailyTargetChanges() {
        let firstCalendar = makeCalendar(
            name: "Multiple",
            trackingType: .multipleDaily,
            entries: [
                makeEntry(year: 2026, month: 1, day: 1, count: 1, completed: true)
            ],
            dailyTarget: 1
        )
        let secondCalendar = makeCalendar(
            id: firstCalendar.id,
            name: "Multiple",
            trackingType: .multipleDaily,
            entries: [
                makeEntry(year: 2026, month: 1, day: 1, count: 1, completed: true)
            ],
            dailyTarget: 2
        )

        #expect(calendarEntriesFingerprint(firstCalendar) != calendarEntriesFingerprint(secondCalendar))
    }

    private func makeCalendar(
        id: UUID = UUID(),
        name: String,
        trackingType: TrackingType,
        entries: [CalendarEntry],
        dailyTarget: Int = 1,
        cadence: CalendarCadence = .daily
    ) -> CustomCalendar {
        CustomCalendar(
            id: id,
            name: name,
            color: "qs-emerald",
            cadence: cadence,
            trackingType: trackingType,
            dailyTarget: dailyTarget,
            entries: Dictionary(uniqueKeysWithValues: entries.map { (dayKey(for: $0.date), $0) })
        )
    }

    private func makeEntry(year: Int, month: Int, day: Int, count: Int, completed: Bool) -> CalendarEntry {
        CalendarEntry(date: makeDate(year: year, month: month, day: day), count: count, completed: completed)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
