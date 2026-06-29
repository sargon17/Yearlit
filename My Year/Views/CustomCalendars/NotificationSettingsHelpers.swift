import Foundation
import SharedModels

enum NotificationSettingsHelpers {
  static func sanitizedAdditionalReminderTimes(
    _ times: [ReminderTime],
    cadence: CalendarCadence,
    trackingType: TrackingType,
    maxTotalReminderTimesPerDay: Int = 5
  ) -> [ReminderTime] {
    guard cadence == .daily, trackingType == .multipleDaily else { return [] }

    let maxAdditionalReminderTimes = max(0, maxTotalReminderTimesPerDay - 1)
    var seen = Set<String>()
    let deduped = times.filter { time in
      let key = time.id
      if seen.contains(key) { return false }
      seen.insert(key)
      return true
    }

    let sorted = deduped.sorted {
      if $0.hour != $1.hour { return $0.hour < $1.hour }
      return $0.minute < $1.minute
    }

    return Array(sorted.prefix(maxAdditionalReminderTimes))
  }

  static func orderedWeekdays() -> [Int] {
    let calendar = Calendar.current
    return (0 ..< 7).map { offset in
      ((calendar.firstWeekday - 1 + offset) % 7) + 1
    }
  }

  static func weekdayName(_ weekday: Int) -> String {
    let symbols = Calendar.current.weekdaySymbols
    let index = max(1, min(7, weekday)) - 1
    return symbols[index]
  }

  static func reminderSummary(
    isEnabled: Bool,
    cadence: CalendarCadence,
    reminderTime: Date,
    reminderWeekday: Int
  ) -> String {
    guard isEnabled else {
      return cadence == .weekly
        ? String(localized: "Off • set a weekly reminder and privacy level.")
        : String(localized: "Off • set a daily reminder and privacy level.")
    }

    let time = reminderTime.formatted(date: .omitted, time: .shortened)
    if cadence == .weekly {
      return String(localized: "On • \(weekdayName(reminderWeekday)) at \(time).")
    }
    return String(localized: "On • every day at \(time).")
  }
}
