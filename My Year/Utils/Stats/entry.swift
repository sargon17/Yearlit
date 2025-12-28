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

func entry(for calendar: CustomCalendar, _ date: Date) -> CalendarEntry? {
  let key = EntryKeyFormatter.shared.string(from: date)
  return calendar.entries[key]
}
