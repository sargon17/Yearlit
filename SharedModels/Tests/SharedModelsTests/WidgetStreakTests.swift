import Foundation
import Testing

@testable import SharedModels

struct WidgetStreakTests {
  @Test func currentStreakKeepsSuccessWhenDuplicateRawDatesNormalizeToSameDay() throws {
    let calendar = makeCalendar()
    let today = try #require(date(year: 2026, month: 1, day: 3, hour: 9))
    let laterSameDay = try #require(date(year: 2026, month: 1, day: 3, hour: 18))
    let successByDay = [
      today: true,
      laterSameDay: false
    ]

    let result = WidgetStreak.currentStreak(
      successByDay: successByDay,
      today: today,
      calendarSystem: calendar,
      allowTodayMissing: false
    )

    #expect(result.streak == 1)
    #expect(!result.isAtRisk)
  }

  @Test func currentStreakMarksAtRiskWhenTodayIsMissingAndPreviousDaySucceeded() throws {
    let calendar = makeCalendar()
    let today = try #require(date(year: 2026, month: 1, day: 3))
    let yesterday = try #require(date(year: 2026, month: 1, day: 2))

    let result = WidgetStreak.currentStreak(
      successByDay: [yesterday: true],
      today: today,
      calendarSystem: calendar
    )

    #expect(result.streak == 1)
    #expect(result.isAtRisk)
  }

  private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date? {
    makeCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour))
  }
}
