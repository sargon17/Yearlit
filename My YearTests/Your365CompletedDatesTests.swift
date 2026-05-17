import Foundation
@testable import My_Year
import SharedModels
import Testing

struct Your365CompletedDatesTests {
    @Test func binaryCalendarsUseOnlyCompletedEntries() {
        let calendar = makeCalendar(trackingType: .binary, entries: [
            "2026-01-01": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 1), count: 1, completed: true),
            "2026-01-02": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 2), count: 1, completed: false),
        ])

        #expect(calendar.your365CompletedDates() == [makeDate(year: 2026, month: 1, day: 1)])
    }

    @Test func counterCalendarsTreatPositiveCountsAsCompleted() {
        let calendar = makeCalendar(trackingType: .counter, entries: [
            "2026-01-01": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 1), count: 2, completed: false),
            "2026-01-02": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 2), count: 0, completed: false),
        ])

        #expect(calendar.your365CompletedDates() == [makeDate(year: 2026, month: 1, day: 1)])
    }

    @Test func multipleDailyCalendarsStillRequireCompletionFlag() {
        let calendar = makeCalendar(trackingType: .multipleDaily, entries: [
            "2026-01-01": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 1), count: 2, completed: false),
            "2026-01-02": CalendarEntry(date: makeDate(year: 2026, month: 1, day: 2), count: 3, completed: true),
        ])

        #expect(calendar.your365CompletedDates() == [makeDate(year: 2026, month: 1, day: 2)])
    }

    private func makeCalendar(
        trackingType: TrackingType,
        entries: [String: CalendarEntry]
    ) -> CustomCalendar {
        CustomCalendar(
            name: "Test",
            color: "qs-blue",
            cadence: .daily,
            trackingType: trackingType,
            trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
            dailyTarget: 3,
            entries: entries
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
