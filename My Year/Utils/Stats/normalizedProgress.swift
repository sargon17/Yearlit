import SharedModels
import SwiftUI

func normalizedProgress(for calendar: CustomCalendar, entry: CalendarEntry?) -> Double {
  guard let e = entry else { return 0 }
  switch calendar.trackingType {
  case .binary:
    return e.completed ? 1 : 0
  case .counter:
    let counts = calendar.entries.values.map { $0.count }
    let q = max(1.0, percentile(counts, p: 0.75))
    return min(Double(e.count) / q, 1.0)
  case .multipleDaily:
    let target = max(1, calendar.dailyTarget)
    return min(Double(e.count) / Double(target), 1.0)
  }
}
