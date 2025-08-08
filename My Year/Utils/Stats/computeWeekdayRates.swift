import SwiftUI

func computeWeekdayRates(
  cal: Calendar,
  dayMeanZ: [Date: Double]
) -> (weekdayRates: [Int: Double], best: (day: Int, rate: Double)?) {
  var wdTotals: [Int: (sumZ: Double, denomDays: Int)] = [:]
  for (day, meanZ) in dayMeanZ {
    let wd = cal.component(.weekday, from: day)
    let cur = wdTotals[wd] ?? (0.0, 0)
    wdTotals[wd] = (cur.sumZ + meanZ, cur.denomDays + 1)
  }

  var weekdayRates: [Int: Double] = [:]
  var best: (day: Int, rate: Double)? = nil
  for (wd, pair) in wdTotals {
    let r = pair.denomDays > 0 ? pair.sumZ / Double(pair.denomDays) : 0
    weekdayRates[wd] = r
    if best == nil || r > best!.rate { best = (wd, r) }
  }
  return (weekdayRates, best)
}
