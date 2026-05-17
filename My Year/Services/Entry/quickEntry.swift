import SharedModels
import SwiftUI

@MainActor
func quickEntry(
    calendar: CustomCalendar,
    date: Date,
    calendarStore: CustomCalendarStore,
    source: CalendarAnalyticsSource = .unknown
) {
    let oldEntry = calendarStore.getEntry(calendarId: calendar.id, date: date)
    calendarStore.quickLogEntry(calendarId: calendar.id, date: date)
    let newEntry = calendarStore.getEntry(calendarId: calendar.id, date: date)
    CalendarAnalyticsTracker.shared.trackEntryMutation(
        calendar: calendar,
        oldEntry: oldEntry,
        newEntry: newEntry,
        source: source
    )
}
