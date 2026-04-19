import SharedModels
import SwiftUI

func computeTodayKeyCount(
    cal: Calendar,
    todayLocal: Date,
    calendars: [CustomCalendar],
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> Int {
    let todayStart = cal.startOfDay(for: todayLocal)
    return calendars.reduce(0) { partial, c in
        let e = entry(for: c, date: todayStart, entriesByCalendar: entriesByCalendar)
        return partial + (e?.count ?? 0)
    }
}
