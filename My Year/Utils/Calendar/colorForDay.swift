import Garnish
import SharedModels
import SwiftUI

private enum DayColors {
  static let inactive = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
  static let active = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)
}

func colorForDay(
  _ day: Date,
  calendar: CustomCalendar,
  today: Date,
  maxCount: Int
) -> Color {

  guard !day.isInFuture else {
    return DayColors.inactive
  }

  let dateKey: String = dayKey(for: day)

  if let entry: CalendarEntry = calendar.entries[dateKey] {
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? Color(calendar.color) : DayColors.active
    case .counter:
      if entry.count > 0 {
        let safeMax = max(maxCount, 1)
        let ratio = max(0.1, Double(entry.count) / Double(safeMax))
        return GarnishColor.blend(.surfaceMuted, with: Color(calendar.color), ratio: ratio)
      } else {
        return DayColors.active
      }
    case .multipleDaily:
      if entry.count > 0 {
        let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
        return Color(calendar.color).opacity(opacity)
      } else {
        return DayColors.active
      }
    }
  }

  return DayColors.active
}
