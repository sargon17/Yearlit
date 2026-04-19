import SharedModels
import SwiftUI

@MainActor
func updateCounterEntry(
    calendarId: UUID,
    date: Date,
    calendarStore: CustomCalendarStore,
    addValue: Int
) {
    var newEntry: CalendarEntry

    if let entry = calendarStore.getEntry(calendarId: calendarId, date: date) {
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
}
