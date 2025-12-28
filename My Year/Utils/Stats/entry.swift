import SharedModels
import SwiftUI

private enum EntryKeyFormatter {
  static let shared: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}

func dayKey(for date: Date) -> String {
  EntryKeyFormatter.shared.string(from: date)
}

func entry(
  for calendarId: UUID,
  dayKey: String,
  entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
  entriesByCalendar[calendarId]?[dayKey]
}
