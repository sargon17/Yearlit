import SharedModels
import SwiftUI

func colorForDay(
  _ day: Date,
  calendar: CustomCalendar,
  valuationStore: ValuationStore,
) -> Color {
  let today = Date()

  if day > today {
    return Color("dot-inactive")
  }

  let dateKey: String = customDateFormatter(date: day)

  if let entry: CalendarEntry = calendar.entries[dateKey] {
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? Color(calendar.color) : Color("dot-active")
    case .counter:
      if entry.count > 0 {
        let maxCount: Int = getMaxCount(calendar: calendar)
        let opacity = max(0.2, Double(entry.count) / Double(maxCount))
        return Color(calendar.color).opacity(opacity)
      } else {
        return Color("dot-active")
      }
    case .multipleDaily:
      if entry.count > 0 {
        let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
        return Color(calendar.color).opacity(opacity)
      } else {
        return Color("dot-active")
      }
    }
  }

  return Color("dot-active")
}
