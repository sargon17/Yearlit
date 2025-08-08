import SwiftUI

func computeWeeklyVolatility(
  cal: Calendar,
  todayLocal: Date,
  anySuccessByDay: [Date: Bool]
) -> Double {
  var weekly: [Double] = []
  var endOfWeek = todayLocal

  for _ in 0..<12 {
    guard let startOfWeek = cal.date(byAdding: .day, value: -6, to: endOfWeek) else { break }
    var succ = 0
    var denom = 0
    var d = startOfWeek
    while d <= endOfWeek {
      succ += (anySuccessByDay[d] == true) ? 1 : 0
      denom += 1
      guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
      d = nd
    }
    weekly.append(denom > 0 ? Double(succ) / Double(denom) : 0)
    guard let prev = cal.date(byAdding: .day, value: -7, to: endOfWeek) else { break }
    endOfWeek = prev
  }

  guard !weekly.isEmpty else { return 0 }
  let mean = weekly.reduce(0, +) / Double(weekly.count)
  let variance = weekly.reduce(0) { $0 + pow($1 - mean, 2) } / Double(weekly.count)
  return sqrt(variance)
}
