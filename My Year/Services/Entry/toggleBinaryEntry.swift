import SharedModels
import SwiftUI

// If the entry does not exist, create a new one with count 1 and completed true.
// If the entry exists, delete it.
// Return the new entry.

@MainActor
func toggleBinaryEntry(
    calendarId: UUID,
    date: Date,
    calendarStore: CustomCalendarStore,
    source: CalendarAnalyticsSource = .unknown
) -> CalendarEntry? {
    let calendar = calendarStore.snapshot.calendar(id: calendarId)
    let oldEntry = calendarStore.getEntry(calendarId: calendarId, date: date)
    let newEntry: CalendarEntry?
    if oldEntry == nil {
        let createdEntry = defaultEntry(date: date, trackingType: .binary)
        calendarStore.addEntry(calendarId: calendarId, entry: createdEntry)
        newEntry = createdEntry
    } else {
        calendarStore.deleteEntry(calendarId: calendarId, date: date)
        newEntry = nil
    }

    if let calendar {
        CalendarAnalyticsTracker.shared.trackEntryMutationDeferred(
            calendar: calendar,
            oldEntry: oldEntry,
            newEntry: newEntry,
            source: source
        )
    }

    return newEntry
}
