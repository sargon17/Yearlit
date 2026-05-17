import SharedModels
import SwiftUI

@MainActor
func quickEntry(
    calendar: CustomCalendar,
    date: Date,
    calendarStore: CustomCalendarStore
) {
    _ = calendarStore.quickLogEntry(calendarId: calendar.id, date: date)
}
