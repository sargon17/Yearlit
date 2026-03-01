import SharedModels
import SwiftUI

func computeTodayKeyCount(
    cal: Calendar,
    todayLocal: Date,
    calendars: [CustomCalendar],
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> Int {
    let todayStart = cal.startOfDay(for: todayLocal)
    let key = dayKey(for: todayStart)
    return calendars.reduce(0) { partial, c in
        let e = entry(for: c.id, dayKey: key, entriesByCalendar: entriesByCalendar)
        return partial + (e?.count ?? 0)
    }
}
