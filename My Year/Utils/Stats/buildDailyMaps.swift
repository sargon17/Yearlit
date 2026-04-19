import SharedModels
import SwiftUI

func buildDailyMaps(
    cal: Calendar,
    year: Int,
    todayLocal: Date,
    calendars: [CustomCalendar],
    entriesByCalendar: [UUID: [String: CalendarEntry]],
    q75ByCalendar: [UUID: Double]
) -> (anySuccessByDay: [Date: Bool], dayMeanZ: [Date: Double]) {
    var anySuccessByDay: [Date: Bool] = [:]
    var dayMeanZ: [Date: Double] = [:]

    if let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
       let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))
    {
        var d = startOfYear
        let last = min(endOfYear, todayLocal)
        while d <= last {
            let key = dayKey(for: d)
            var any = false
            var zAccum = 0.0
            var zDenom = 0.0

            for c in calendars {
                let e = entry(for: c.id, dayKey: key, entriesByCalendar: entriesByCalendar)
                if isEntrySuccess(e, calendar: c) { any = true }
                if e != nil {
                    zAccum += normalizedProgress(for: c, entry: e, q75: q75ByCalendar[c.id])
                    zDenom += 1
                }
            }

            anySuccessByDay[d] = any
            if zDenom > 0 { dayMeanZ[d] = zAccum / zDenom }

            guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = nd
        }
    }

    return (anySuccessByDay, dayMeanZ)
}
