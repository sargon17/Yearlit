import SharedModels
import SwiftUI

func aggregateCounts(
  cal: Calendar,
  calendars: [CustomCalendar]
) -> (totalCount: Int, perDayTotal: [Date: Int]) {
  var totalCount = 0
  var perDayTotal: [Date: Int] = [:]
  for calendar in calendars {
    for entry in calendar.entries.values {
      totalCount += entry.count
      let day = cal.startOfDay(for: entry.date)
      perDayTotal[day, default: 0] += entry.count
    }
  }
  return (totalCount, perDayTotal)
}
