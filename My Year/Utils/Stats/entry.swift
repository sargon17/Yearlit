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
    for calendar: CustomCalendar,
    date: Date,
    entriesByCalendarByBucket: [UUID: [Date: CalendarEntry]]
) -> CalendarEntry? {
    entriesByCalendarByBucket[calendar.id]?[calendar.bucketDate(for: date)]
}

func entry(
    for calendarId: UUID,
    dayKey: String,
    entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
    entriesByCalendar[calendarId]?[dayKey]
}

func buildEntriesByCalendarByBucket(calendars: [CustomCalendar]) -> [UUID: [Date: CalendarEntry]] {
    Dictionary(uniqueKeysWithValues: calendars.map { calendar in
        var entriesByBucket: [Date: CalendarEntry] = [:]

        for entry in calendar.entries.values {
            let bucketDate = calendar.bucketDate(for: entry.date)

            guard let existing = entriesByBucket[bucketDate] else {
                entriesByBucket[bucketDate] = entry
                continue
            }

            entriesByBucket[bucketDate] = mergeEntries(existing, entry, for: calendar)
        }

        return (calendar.id, entriesByBucket)
    })
}

private func mergeEntries(_ lhs: CalendarEntry, _ rhs: CalendarEntry, for calendar: CustomCalendar) -> CalendarEntry {
    let mergedDate = max(lhs.date, rhs.date)

    switch calendar.trackingType {
    case .binary:
        return CalendarEntry(
            date: mergedDate,
            count: max(lhs.count, rhs.count),
            completed: lhs.completed || rhs.completed
        )
    case .counter, .multipleDaily:
        return CalendarEntry(
            date: mergedDate,
            count: lhs.count + rhs.count,
            completed: lhs.completed || rhs.completed
        )
    }
}
