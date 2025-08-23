import SwiftUI

func computeMonthlyBinaryRates(
  cal: Calendar,
  year: Int,
  todayLocal: Date,
  isSuccessOn: (Date) -> Bool
) -> [Int: Double] {
  var monthly: [Int: Double] = [:]
  for m in 1...12 {
    guard let start = cal.date(from: DateComponents(year: year, month: m, day: 1)),
      let range = cal.range(of: .day, in: .month, for: start)
    else { continue }

    let isCurrentMonth =
      (year == cal.component(.year, from: todayLocal)
        && m == cal.component(.month, from: todayLocal))
    let lastDay = isCurrentMonth ? cal.component(.day, from: todayLocal) : range.count
    guard lastDay > 0 else {
      monthly[m] = 0
      continue
    }

    var succ = 0
    for day in 1...lastDay {
      if let date = cal.date(from: DateComponents(year: year, month: m, day: day)),
        isSuccessOn(date)
      {
        succ += 1
      }
    }
    monthly[m] = Double(succ) / Double(lastDay)
  }
  return monthly
}
