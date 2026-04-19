import SharedModels
import SwiftUI

func dayKey(for date: Date) -> String {
    DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date))
}

func entryKey(for calendar: CustomCalendar, date: Date) -> String {
    calendar.entryKey(for: date)
}

func entry(for calendar: CustomCalendar, date: Date) -> CalendarEntry? {
    calendar.entry(for: date)
}

func entry(
    for calendar: CustomCalendar,
    date: Date,
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
    entriesByCalendar[calendar.id]?[calendar.entryKey(for: date)]
}

func entry(
    for calendarId: UUID,
    dayKey: String,
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
    entriesByCalendar[calendarId]?[dayKey]
}
