import Garnish
import SharedModels
import SwiftUI

private enum DayKeyFormatterLocal {
  static let shared: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}

func colorForDay(
  _ day: Date,
  calendar: CustomCalendar,
  today: Date,
  maxCount: Int
) -> Color {

  let inactiveColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
  let activeColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)

  guard !day.isInFuture else {
    return inactiveColor
  }

  let dateKey: String = DayKeyFormatterLocal.shared.string(from: day)

  if let entry: CalendarEntry = calendar.entries[dateKey] {
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? Color(calendar.color) : activeColor
    case .counter:
      if entry.count > 0 {
        let safeMax = max(maxCount, 1)
        let ratio = max(0.1, Double(entry.count) / Double(safeMax))
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
