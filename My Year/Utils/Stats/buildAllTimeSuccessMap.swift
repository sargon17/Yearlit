import SharedModels
import SwiftUI

func buildAllTimeSuccessDays(
    cal: Calendar,
    todayLocal: Date,
    calendars: [CustomCalendar]
) -> Set<Date> {
    let today = cal.startOfDay(for: todayLocal)
    var successDays = Set<Date>()

    for calendar in calendars {
        for entry in calendar.entries.values {
            guard isEntrySuccess(entry, calendar: calendar) else { continue }

            switch calendar.cadence {
            case .daily:
                let day = cal.startOfDay(for: entry.date)
                if day <= today {
                    successDays.insert(day)
                }

            case .weekly:
                var cursor = calendar.bucketDate(for: entry.date)
                guard let weekEnd = cal.date(byAdding: .day, value: 6, to: cursor) else { continue }
                let lastDay = min(today, weekEnd)

                while cursor <= lastDay {
                    successDays.insert(cal.startOfDay(for: cursor))
                    guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
                    cursor = next
                }
            }
        }
    }

    return successDays
}
