import Foundation

enum LocalDayCalendar {
  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar
  }

  static func startOfDay(for date: Date) -> Date {
    calendar.startOfDay(for: date)
  }
}
