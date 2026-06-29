import Foundation
import SharedModels

struct CustomCalendarOptimisticEntryOverride {
  let calendarId: UUID
  let dayKey: String
  let entry: CalendarEntry?
}

enum CustomCalendarOptimisticEntries {
  static func applying(
    _ overrides: [String: CustomCalendarOptimisticEntryOverride],
    to calendar: CustomCalendar
  ) -> CustomCalendar {
    var calendar = calendar
    for override in overrides.values where override.calendarId == calendar.id {
      if let entry = override.entry {
        calendar.entries[override.dayKey] = entry
      } else {
        calendar.entries.removeValue(forKey: override.dayKey)
      }
    }
    return calendar
  }

  static func override(
    for calendar: CustomCalendar,
    date: Date,
    entry: CalendarEntry?
  ) -> (key: String, value: CustomCalendarOptimisticEntryOverride) {
    let dayKey = calendar.entryKey(for: date)
    return (
      "\(calendar.id.uuidString)|\(dayKey)",
      CustomCalendarOptimisticEntryOverride(
        calendarId: calendar.id,
        dayKey: dayKey,
        entry: entry
      )
    )
  }

  static func signature(_ overrides: [String: CustomCalendarOptimisticEntryOverride]) -> String {
    overrides
      .sorted { $0.key < $1.key }
      .map { key, override in
        let entrySignature =
          override.entry.map {
            "\(dayKey(for: $0.date)):\($0.count):\($0.completed)"
          } ?? "nil"
        return "\(key):\(entrySignature)"
      }
      .joined(separator: ",")
  }
}
