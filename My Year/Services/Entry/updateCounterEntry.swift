import SharedModels
import SwiftUI

@MainActor
func updateCounterEntry(
    calendarId: UUID,
    date: Date,
    calendarStore: CustomCalendarStore,
    addValue: Int,
    source: CalendarAnalyticsSource = .unknown
) {
    let calendar = calendarStore.snapshot.calendar(id: calendarId)
    let oldEntry = calendarStore.getEntry(calendarId: calendarId, date: date)
    var newEntry: CalendarEntry

    if let entry = oldEntry {
        let newValue = entry.count + addValue
        let isCompleted = newValue > 0
        newEntry = CalendarEntry(
            date: date,
            count: newValue,
            completed: isCompleted
        )
    } else {
        newEntry = CalendarEntry(date: date, count: addValue, completed: addValue > 0)
    }

    calendarStore.addEntry(calendarId: calendarId, entry: newEntry)
    if let calendar {
        CalendarAnalyticsTracker.shared.trackEntryMutationDeferred(
            calendar: calendar,
            oldEntry: oldEntry,
            newEntry: newEntry,
            source: source
        )
    }
}
