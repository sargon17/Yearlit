import Garnish
import SharedModels
import SwiftUI

private func inactiveDayColor() -> Color {
  GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.04)
}

private func activeDayColor() -> Color {
  GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.12)
}

func colorForDay(
  _ day: Date,
  calendar: CustomCalendar,
  today: Date,
  maxCount: Int
) -> Color {

  guard !day.isInFuture else {
    return inactiveDayColor()
  }

  let dateKey: String = dayKey(for: day)

  if let entry: CalendarEntry = calendar.entries[dateKey] {
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? Color(calendar.color) : activeDayColor()
    case .counter:
      if entry.count > 0 {
        let safeMax = max(maxCount, 1)
        let ratio = max(0.1, Double(entry.count) / Double(safeMax))
        return GarnishColor.blend(.surfaceMuted, with: Color(calendar.color), ratio: ratio)
      } else {
        return activeDayColor()
      }
    case .multipleDaily:
      if entry.count > 0 {
        let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
        return Color(calendar.color).opacity(opacity)
      } else {
        return activeDayColor()
      }
    }
  }

  return activeDayColor()
}
