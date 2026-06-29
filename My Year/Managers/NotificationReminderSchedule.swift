import Foundation
@preconcurrency import SharedModels

struct ReminderScheduleTime {
  let hour: Int
  let minute: Int
  let additionalIndex: Int?

  var isValid: Bool {
    (0 ... 23).contains(hour) && (0 ... 59).contains(minute)
  }

  func notificationId(for calendarId: UUID) -> String {
    guard let additionalIndex else {
      return calendarId.uuidString
    }
    return "\(calendarId.uuidString)-\(additionalIndex)"
  }
}

func reminderTimes(for calendar: CustomCalendar) -> [ReminderScheduleTime] {
  var times: [ReminderScheduleTime] = []
  if let hour = calendar.reminderHour, let minute = calendar.reminderMinute {
    times.append(ReminderScheduleTime(hour: hour, minute: minute, additionalIndex: nil))
  }

  if calendar.cadence == .daily {
    times.append(
      contentsOf: calendar.additionalReminderTimes.enumerated().map { index, reminderTime in
        ReminderScheduleTime(
          hour: reminderTime.hour,
          minute: reminderTime.minute,
          additionalIndex: index
        )
      }
    )
  }

  return times.filter(\.isValid)
}
