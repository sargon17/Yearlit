import SwiftUI

func computeRollingStatsSingle(
  cal: Calendar,
  todayLocal: Date,
  zOn: (Date) -> Double,
  isSuccessOn: (Date) -> Bool
) -> (cr30: Double, avg7: Double, avg30: Double) {
  let dates = lastNDates(cal: cal, todayLocal: todayLocal, n: 30)
  guard !dates.isEmpty else { return (0, 0, 0) }

  var succ = 0
  var zSum7 = 0.0
  var zSum30 = 0.0
  for (i, d) in dates.enumerated() {
    if isSuccessOn(d) { succ += 1 }
    let z = zOn(d)
    zSum30 += z
    if i >= dates.count - 7 { zSum7 += z }
  }
  let cr30 = Double(succ) / Double(dates.count)
  let avg7 = zSum7 / Double(min(7, dates.count))
  let avg30 = zSum30 / Double(dates.count)
  return (cr30, avg7, avg30)
}
