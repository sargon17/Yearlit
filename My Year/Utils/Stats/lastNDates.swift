import SwiftUI

func lastNDates(cal: Calendar, todayLocal: Date, n: Int) -> [Date] {
  guard n > 0 else { return [] }
  let fallbackStart = cal.startOfDay(for: todayLocal)
  let start = cal.startOfDay(
    for: cal.date(byAdding: .day, value: -(n - 1), to: todayLocal) ?? fallbackStart
  )
  return (0..<n)
    .compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    .filter { $0 <= todayLocal }
}
