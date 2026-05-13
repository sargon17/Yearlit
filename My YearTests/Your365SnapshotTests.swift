import Foundation
import SharedModels
import Testing

struct Your365SnapshotTests {
    @Test func firstYearSnapshotStartsAtTrackingDateAndMarksFutureDays() {
        let start = makeDate(year: 2026, month: 1, day: 1)
        let today = makeDate(year: 2026, month: 1, day: 11)
        let completed: Set<Date> = [
            makeDate(year: 2026, month: 1, day: 1),
            makeDate(year: 2026, month: 1, day: 5),
        ]

        let snapshot = Your365Snapshot.makeFirstYear(
            trackingStartedAt: start,
            completedDates: completed,
            today: today
        )

        #expect(snapshot.cells.count == 365)
        #expect(snapshot.cells.first?.dayNumber == 1)
        #expect(snapshot.cells.first?.date == start)
        #expect(snapshot.cells[4].state == .completed)
        #expect(snapshot.cells[10].state == .todayPending)
        #expect(snapshot.cells[11].state == .future)
        #expect(snapshot.cells.last?.dayNumber == 365)
    }

    @Test func firstYearSnapshotKeeps365DayBoundaryStable() {
        let start = makeDate(year: 2025, month: 1, day: 1)
        let today = makeDate(year: 2026, month: 1, day: 1)

        let snapshot = Your365Snapshot.makeFirstYear(trackingStartedAt: start, completedDates: [], today: today)

        #expect(snapshot.cells.count == 365)
        #expect(snapshot.cells.first?.dayNumber == 1)
        #expect(snapshot.cells.last?.dayNumber == 365)
        #expect(snapshot.cells.last?.date == makeDate(year: 2025, month: 12, day: 31))
        #expect(snapshot.cells.last?.state == .missed)
    }

    @Test func firstYearSnapshotKeepsDay365InFirstYearMode() {
        let start = makeDate(year: 2026, month: 1, day: 1)
        let today = makeDate(year: 2026, month: 12, day: 31)

        let snapshot = Your365Snapshot.makeFirstYear(trackingStartedAt: start, completedDates: [], today: today)

        #expect(snapshot.cells.count == 365)
        #expect(snapshot.cells.last?.date == today)
        #expect(snapshot.cells.last?.state == .todayPending)
    }

    @Test func latest365SnapshotEndsTodayForMatureCalendar() {
        let start = makeDate(year: 2024, month: 1, day: 1)
        let today = makeDate(year: 2025, month: 2, day: 1)
        let completed: Set<Date> = [
            makeDate(year: 2025, month: 1, day: 31),
            makeDate(year: 2025, month: 2, day: 1),
        ]

        let snapshot = Your365Snapshot.makeLatest365Days(
            trackingStartedAt: start,
            completedDates: completed,
            today: today
        )

        #expect(snapshot.cells.count == 365)
        #expect(snapshot.cells.first?.date == LocalDayCalendar.startOfDay(for: Calendar.current.date(byAdding: .day, value: -364, to: today)!))
        #expect(snapshot.cells.last?.date == today)
        #expect(snapshot.cells.last?.state == .completed)
        #expect(snapshot.cells.contains(where: { $0.state == .completed }))
    }

    @Test func latest365SnapshotMarksPreStartDaysAsNotTracked() {
        let start = makeDate(year: 2026, month: 1, day: 20)
        let today = makeDate(year: 2026, month: 1, day: 25)

        let snapshot = Your365Snapshot.makeLatest365Days(trackingStartedAt: start, completedDates: [], today: today)

        #expect(snapshot.cells.count == 365)
        #expect(snapshot.cells.prefix(5).allSatisfy { $0.state == .notTracked })
        #expect(snapshot.cells.last?.date == today)
    }

    @Test func dayIndexingSurvivesDstStyleCalendarGaps() {
        let originalTimeZone = TimeZone.default
        let dstZone = TimeZone(identifier: "America/New_York")!
        TimeZone.default = dstZone
        defer { TimeZone.default = originalTimeZone }

        let start = makeDate(year: 2026, month: 3, day: 7)
        let today = makeDate(year: 2026, month: 3, day: 10)

        let snapshot = Your365Snapshot.makeFirstYear(trackingStartedAt: start, completedDates: [], today: today)
        let dayTwo = snapshot.cells[1]
        let dayThree = snapshot.cells[2]

        #expect(Calendar.current.dateComponents([.day], from: dayTwo.date, to: dayThree.date).day == 1)
        #expect(dayTwo.dayNumber == 2)
        #expect(dayThree.dayNumber == 3)
    }

    @Test func weeklyCalendarsDoNotProduceYour365Snapshots() {
        let weekly = CustomCalendar(
            name: "Weekly",
            color: "qs-blue",
            cadence: .weekly,
            trackingType: .binary,
            dailyTarget: 1
        )

        #expect(weekly.makeYour365Snapshot(completedDates: [], today: makeDate(year: 2026, month: 1, day: 1)) == nil)
        #expect(weekly.makeFirstYearYour365Snapshot(completedDates: [], today: makeDate(year: 2026, month: 1, day: 1)) == nil)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
