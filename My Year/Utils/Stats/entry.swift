import SharedModels
import SwiftUI

func dayKey(for date: Date) -> String {
    DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date))
}

func entry(
    for calendarId: UUID,
    dayKey: String,
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
    entriesByCalendar[calendarId]?[dayKey]
}
