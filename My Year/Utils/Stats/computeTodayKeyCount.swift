import SharedModels
import SwiftUI

func computeTodayKeyCount(
  cal: Calendar,
  todayLocal: Date,
  calendars: [CustomCalendar],
  store: CustomCalendarStore
) -> Int {
  let todayStart = cal.startOfDay(for: todayLocal)
  return calendars.reduce(0) { partial, c in
    let e = store.getEntry(calendarId: c.id, date: todayStart)
    return partial + (e?.count ?? 0)
  }
}
