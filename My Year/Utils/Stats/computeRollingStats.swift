import SharedModels
import SwiftUI

func computeRollingStats(
  cal: Calendar,
  todayLocal: Date,
  calendars: [CustomCalendar],
  anySuccessByDay: [Date: Bool],
  store: CustomCalendarStore
) -> (cr30: Double, avg7: Double, avg30: Double) {
  let d30 = lastNDates(cal: cal, todayLocal: todayLocal, n: 30)
  var succ30 = 0
  var zSum7 = 0.0
  var zSum30 = 0.0

  for (i, d) in d30.enumerated() {
    if anySuccessByDay[d] == true { succ30 += 1 }

    var zAccum = 0.0
    var zCount = 0.0
    for c in calendars {
      if let e = entry(for: c, d, store: store) {
        zAccum += normalizedProgress(for: c, entry: e)
        zCount += 1
      }
    }
    let meanZ = zCount > 0 ? zAccum / zCount : 0
    zSum30 += meanZ
    if i >= d30.count - 7 { zSum7 += meanZ }
  }

  let cr30 = d30.isEmpty ? 0 : Double(succ30) / Double(d30.count)
  let avg7 = d30.isEmpty ? 0 : zSum7 / Double(min(7, d30.count))
  let avg30 = d30.isEmpty ? 0 : zSum30 / Double(d30.count)
  return (cr30, avg7, avg30)
}
