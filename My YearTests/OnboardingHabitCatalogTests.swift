@testable import My_Year
import Foundation
import SharedModels
import Testing

struct OnboardingHabitCatalogTests {
    @Test func everyIdentityReturnsThreeTinyHabits() {
        for commitment in IdentityCommitment.allCases {
            let habits = OnboardingHabitCatalog.habits(for: commitment)
            #expect(habits.count == 3)
            #expect(Set(habits).count == 3)
        }
    }

    @Test func factoryBuildsDailyBinaryCalendarWithoutReminders() {
        let today = makeDate(year: 2026, month: 5, day: 18)
        let calendar = OnboardingFirstCalendarFactory.makeCalendar(title: "Read 2 pages", today: today)

        #expect(calendar.name == "Read 2 pages")
        #expect(calendar.color == "qs-orange")
        #expect(calendar.cadence == .daily)
        #expect(calendar.trackingType == .binary)
        #expect(calendar.dailyTarget == 1)
        #expect(calendar.trackingStartedAt == LocalDayCalendar.startOfDay(for: today))
        #expect(calendar.recurringReminderEnabled == false)
        #expect(calendar.reminderHour == nil)
        #expect(calendar.reminderMinute == nil)
        #expect(calendar.reminderWeekday == nil)
        #expect(calendar.additionalReminderTimes.isEmpty)
        #expect(calendar.isArchived == false)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
