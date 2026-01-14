import Foundation

public enum WidgetStreak {
  public static func currentStreak(
    calendar: CustomCalendar,
    today: Date = Date(),
    calendarSystem: Calendar = WidgetStreak.makeLocalCalendar(),
    allowTodayMissing: Bool = true
  ) -> (streak: Int, isAtRisk: Bool) {
    var successByDay: [Date: Bool] = [:]
    for entry in calendar.entries.values {
      let day = calendarSystem.startOfDay(for: entry.date)
      if isEntrySuccess(entry, calendar: calendar) {
        successByDay[day] = true
      }
    }

    return currentStreak(
      successByDay: successByDay,
      today: today,
      calendarSystem: calendarSystem,
      allowTodayMissing: allowTodayMissing
    )
  }

  public static func currentStreak(
    successByDay: [Date: Bool],
    today: Date = Date(),
    calendarSystem: Calendar = WidgetStreak.makeLocalCalendar(),
    allowTodayMissing: Bool = true
  ) -> (streak: Int, isAtRisk: Bool) {
    guard !successByDay.isEmpty else { return (0, false) }

    let normalizedToday = calendarSystem.startOfDay(for: today)
    var normalized: [Date: Bool] = [:]
    for (date, success) in successByDay {
      normalized[calendarSystem.startOfDay(for: date)] = success
    }

    let todaySuccess = normalized[normalizedToday]
    let shouldSkipToday = allowTodayMissing && (todaySuccess == nil || todaySuccess == false)

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

    while normalized[cursor] == true {
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

  public static func makeLocalCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar
  }
}
