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

    private func makeCalendar(
        name: String,
        trackingType: TrackingType,
        entries: [CalendarEntry],
        dailyTarget: Int = 1
    ) -> CustomCalendar {
        CustomCalendar(
            name: name,
            color: "qs-emerald",
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
