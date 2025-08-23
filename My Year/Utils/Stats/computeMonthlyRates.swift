import SwiftUI

func computeMonthlyRates(
  cal: Calendar,
  year: Int,
  todayLocal: Date,
  dayMeanZ: [Date: Double]
) -> [Int: Double] {
  var monthly: [Int: Double] = [:]
  for m in 1...12 {
    guard let start = cal.date(from: DateComponents(year: year, month: m, day: 1)) else { continue }
    guard let range = cal.range(of: .day, in: .month, for: start) else { continue }

    let isCurrentMonth =
      (year == cal.component(.year, from: todayLocal) && m == cal.component(.month, from: todayLocal))
    let lastDay = isCurrentMonth ? cal.component(.day, from: todayLocal) : range.count
    if lastDay <= 0 {
      monthly[m] = 0
      continue
    }

    var sumZ = 0.0
    var denomDays = 0
    for day in 1...lastDay {
      if let dt = cal.date(from: DateComponents(year: year, month: m, day: day)),
        let meanZ = dayMeanZ[dt]
      {
        sumZ += meanZ
        denomDays += 1
      }
    }
    monthly[m] = denomDays > 0 ? sumZ / Double(denomDays) : 0
  }
  return monthly
}
