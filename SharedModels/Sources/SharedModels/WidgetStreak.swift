import Foundation

public enum WidgetStreak {
  public static func currentStreak(
    calendar: CustomCalendar,
    today: Date = Date(),
    calendarSystem: Calendar = WidgetStreak.makeLocalCalendar(),
    allowTodayMissing: Bool = true
  ) -> (streak: Int, isAtRisk: Bool) {
    let normalizedToday = calendarSystem.startOfDay(for: today)
    let todayKey = dayKey(for: normalizedToday)
    let todayEntry = calendar.entries[todayKey]
    let shouldSkipToday = allowTodayMissing
      && (todayEntry == nil || !isEntrySuccess(todayEntry!, calendar: calendar))

    var streak = 0
    var cursor = normalizedToday
    var isAtRisk = false

    if shouldSkipToday {
      guard let previous = calendarSystem.date(byAdding: .day, value: -1, to: normalizedToday) else {
        return (0, false)
      }
      cursor = calendarSystem.startOfDay(for: previous)
      isAtRisk = true
    }

    while true {
      let key = dayKey(for: cursor)
      guard let entry = calendar.entries[key], isEntrySuccess(entry, calendar: calendar) else {
        break
      }
      streak += 1
      guard let previous = calendarSystem.date(byAdding: .day, value: -1, to: cursor) else {
        break
      }
      cursor = calendarSystem.startOfDay(for: previous)
    }

    if streak == 0 {
      isAtRisk = false
    }

    return (streak, isAtRisk)
  }

  private static func isEntrySuccess(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter:
      return entry.count > 0
    case .multipleDaily:
      return entry.count >= calendar.dailyTarget
    }
  }

  private static func isEntryEmpty(_ entry: CalendarEntry) -> Bool {
    entry.count == 0 && entry.completed == false
  }

  private static func dayKey(for date: Date) -> String {
    DayKeyFormatter.shared.string(from: date)
  }

  public static func makeLocalCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar
  }
}
