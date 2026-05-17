import Foundation
@testable import My_Year
import SharedModels
import Testing

struct CalendarShareTemplateAvailabilityTests {
    @Test func dailyCalendarsExposeYour365WhenSnapshotExists() {
        let calendar = makeCalendar(cadence: .daily, start: makeDate(year: 2026, month: 1, day: 1))

        let templates = availableShareTemplates(for: calendar, today: makeDate(year: 2026, month: 1, day: 10))

        #expect(templates.contains(.your365))
        #expect(templates.contains(.yearCard))
        #expect(templates.contains(.performance))
    }

    @Test func weeklyCalendarsDoNotExposeYour365() {
        let calendar = makeCalendar(cadence: .weekly, start: makeDate(year: 2026, month: 1, day: 1))

        let templates = availableShareTemplates(for: calendar, today: makeDate(year: 2026, month: 1, day: 10))

        #expect(!templates.contains(.your365))
        #expect(templates.contains(.yearCard))
    }

    private func makeCalendar(cadence: CalendarCadence, start: Date) -> CustomCalendar {
        CustomCalendar(
            name: "Test",
            color: "qs-blue",
            cadence: cadence,
            trackingType: .binary,
            trackingStartedAt: start,
            dailyTarget: 1
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
