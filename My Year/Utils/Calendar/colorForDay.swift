import Garnish
import SharedModels
import SwiftUI

func colorForDay(
  _ day: Date,
  calendar: CustomCalendar,
  today: Date
) -> Color {

  let inactiveColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
  let activeColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)

  guard !day.isInFuture else {
    return inactiveColor
  }

  let dateKey: String = customDateFormatter(date: day)

  if let entry: CalendarEntry = calendar.entries[dateKey] {
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? Color(calendar.color) : activeColor
    case .counter:
      if entry.count > 0 {
        let maxCount: Int = getMaxCount(calendar: calendar)
        let ratio = max(0.1, Double(entry.count) / Double(maxCount))
        return GarnishColor.blend(.surfaceMuted, with: Color(calendar.color), ratio: ratio)
      } else {
        return activeColor
      }
    case .multipleDaily:
      if entry.count > 0 {
        let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
        return Color(calendar.color).opacity(opacity)
      } else {
        return activeColor
      }
    }
  }

  return activeColor
}
