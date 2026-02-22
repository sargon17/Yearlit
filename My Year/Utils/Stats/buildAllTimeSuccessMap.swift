import SharedModels
import SwiftUI

func buildAllTimeSuccessMap(
    cal: Calendar,
    todayLocal: Date,
    calendars: [CustomCalendar]
) -> [Date: Bool] {
    let today = cal.startOfDay(for: todayLocal)
    var earliest: Date?
    var successDays = Set<Date>()

    for calendar in calendars {
        for entry in calendar.entries.values {
            let day = cal.startOfDay(for: entry.date)
            if day > today { continue }
            if earliest == nil || day < earliest! { earliest = day }
            if isEntrySuccess(entry, calendar: calendar) {
                successDays.insert(day)
            }
        }
    }

    guard let start = earliest else { return [:] }

    var anySuccessByDay: [Date: Bool] = [:]
    var cursor = start
    while cursor <= today {
        anySuccessByDay[cursor] = successDays.contains(cursor)
        guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
        cursor = next
    }

    return anySuccessByDay
}
