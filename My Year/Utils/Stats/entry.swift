import SharedModels
import SwiftUI

private enum EntryKeyFormatter {
  static let shared: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .autoupdatingCurrent
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}

func dayKey(for date: Date) -> String {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  let canonicalDate = calendar.startOfDay(for: date)
  return EntryKeyFormatter.shared.string(from: canonicalDate)
}

func entry(
  for calendarId: UUID,
  dayKey: String,
  entriesByCalendar: [UUID: [String: CalendarEntry]]
) -> CalendarEntry? {
  entriesByCalendar[calendarId]?[dayKey]
}
