import SharedModels
import SwiftUI

@MainActor
func updateMultipleDailyEntry(
    calendar: CustomCalendar,
    date: Date,
    calendarStore: CustomCalendarStore,
    addValue: Int,
    source: CalendarAnalyticsSource = .unknown
) {
    let oldEntry = calendarStore.getEntry(calendarId: calendar.id, date: date)
    var newEntry: CalendarEntry
    let calendarId = calendar.id

    if let entry = oldEntry {
        let newValue = entry.count + addValue
        let isCompleted = newValue >= calendar.dailyTarget

        newEntry = CalendarEntry(
            date: date,
            count: newValue,
            completed: isCompleted
        )
    } else {
        newEntry = CalendarEntry(
            date: date,
            count: addValue,
            completed: addValue >= calendar.dailyTarget
        )
    }

    calendarStore.addEntry(calendarId: calendarId, entry: newEntry)
    CalendarAnalyticsTracker.shared.trackEntryMutation(
        calendar: calendar,
        oldEntry: oldEntry,
        newEntry: newEntry,
        source: source
    )
}
