import SharedModels
import SwiftUI

func quickEntry(
    calendar: CustomCalendar,
    date: Date,
    calendarStore: CustomCalendarStore
) {
    let today = date

    switch calendar.trackingType {
    case .binary:
        _ = toggleBinaryEntry(
            calendarId: calendar.id,
            date: today,
            calendarStore: calendarStore
        )
    case .counter:
        updateCounterEntry(
            calendarId: calendar.id,
            date: today,
            calendarStore: calendarStore,
            addValue: calendar.defaultRecordValue ?? 1
        )
    case .multipleDaily:
        updateMultipleDailyEntry(
            calendar: calendar,
            date: today,
            calendarStore: calendarStore,
            addValue: calendar.defaultRecordValue ?? 1
        )
    }
}
