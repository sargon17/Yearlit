import SharedModels
import SwiftUI

// If the entry does not exist, create a new one with count 1 and completed true.
// If the entry exists, delete it.
// Return the new entry.

func toggleBinaryEntry(
    calendarId: UUID,
    date: Date,
    calendarStore: CustomCalendarStore
) -> CalendarEntry? {
    if calendarStore.getEntry(calendarId: calendarId, date: date) == nil {
        let newEntry = defaultEntry(date: date, trackingType: .binary)
        calendarStore.addEntry(calendarId: calendarId, entry: newEntry)
        if let calendar = calendarStore.calendars.first(where: { $0.id == calendarId }) {
            syncNotificationsAfterEntryChange(for: calendar, store: calendarStore)
        }
        return newEntry
    }

    calendarStore.deleteEntry(calendarId: calendarId, date: date)
    if let calendar = calendarStore.calendars.first(where: { $0.id == calendarId }) {
        syncNotificationsAfterEntryChange(for: calendar, store: calendarStore)
    }
    return nil
}
