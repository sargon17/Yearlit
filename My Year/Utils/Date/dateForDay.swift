import Foundation
import SharedModels

func dateForDay(_ zeroBasedDay: Int, in year: Int) -> Date {
  let calendar = LocalDayCalendar.calendar
  let resolvedYear = min(9999, max(1, year))
  guard let startOfYear = calendar.date(from: DateComponents(year: resolvedYear, month: 1, day: 1)) else {
    return Date(timeIntervalSince1970: 0)
  }
  return calendar.date(byAdding: .day, value: zeroBasedDay, to: startOfYear) ?? startOfYear
}
