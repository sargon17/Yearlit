import SwiftUI

func lastNDates(cal: Calendar, todayLocal: Date, n: Int) -> [Date] {
  let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(n - 1), to: todayLocal)!)
  return (0..<n)
    .compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    .filter { $0 <= todayLocal }
}
