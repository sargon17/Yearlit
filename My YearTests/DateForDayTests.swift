import Foundation
import SharedModels
import Testing

@testable import My_Year

struct DateForDayTests {
  @Test func resolvesZeroBasedDayWithinSelectedYear() {
    let date = dateForDay(31, in: 2026)
    let components = LocalDayCalendar.calendar.dateComponents([.year, .month, .day], from: date)

    #expect(components.year == 2026)
    #expect(components.month == 2)
    #expect(components.day == 1)
  }

  @Test func invalidYearDoesNotFallBackToToday() {
    let date = dateForDay(0, in: 0)
    let year = LocalDayCalendar.calendar.component(.year, from: date)

    #expect(year == 1)
  }
}
