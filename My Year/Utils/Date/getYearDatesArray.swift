import Foundation
import SwiftDate

public func getYearDatesArray() -> [Date] {
  let currentYear = Calendar.current.component(.year, from: Date())
  return getYearDatesArray(for: currentYear)
}

public func getYearDatesArray(for year: Int) -> [Date] {
  let calendar = Calendar.current
  guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
    let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
  else {
    return []
  }

  var dates: [Date] = []
  var current = startDate
  while current <= endDate {
    dates.append(current)
    guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
    current = next
  }

  return dates
}
