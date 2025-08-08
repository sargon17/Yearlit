import SharedModels
import SwiftUI

func computeWeekdayRatesSingle(
  cal: Calendar,
  year: Int,
  todayLocal: Date,
  trackingType: TrackingType,
  zOn: (Date) -> Double,
  isSuccessOn: (Date) -> Bool,
  normalizeToMax: Bool
) -> (weekdayRates: [Int: Double], best: (day: Int, rate: Double)?) {
  var totals: [Int: (sum: Double, denom: Int)] = [:]

  if let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
    let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))
  {

    var d = startOfYear
    let endDate = min(todayLocal, endOfYear)
    while d <= endDate {
      let wd = cal.component(.weekday, from: d)
      let value: Double = {
        switch trackingType {
        case .binary: return isSuccessOn(d) ? 1.0 : 0.0
        case .counter, .multipleDaily: return zOn(d)  // già 0..1
        }
      }()
      let cur = totals[wd] ?? (0.0, 0)
      totals[wd] = (cur.sum + value, cur.denom + 1)
      d = cal.date(byAdding: .day, value: 1, to: d)!
    }
  }

  var rates: [Int: Double] = [:]
  var best: (day: Int, rate: Double)? = nil
  for (wd, pair) in totals {
    let r = pair.denom > 0 ? pair.sum / Double(pair.denom) : 0
    rates[wd] = r
    if best == nil || r > best!.rate { best = (wd, r) }
  }

  if normalizeToMax, let maxR = rates.values.max(), maxR > 0 {
    rates = rates.mapValues { $0 / maxR }
  }
  return (rates, best)
}
