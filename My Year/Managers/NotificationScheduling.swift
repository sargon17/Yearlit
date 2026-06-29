import Foundation
@preconcurrency import SharedModels
import UserNotifications

public func scheduleNotifications(
  for calendar: CustomCalendar,
  store: CustomCalendarStore? = nil,
  completion: @escaping (Result<Void, NotificationError>) -> Void = { _ in }
) {
  removePendingNotifications(for: calendar.id) {
    guard shouldScheduleNotifications(for: calendar) else {
      completion(.success(()))
      return
    }

    let reminderTimes = reminderTimes(for: calendar)
    guard !reminderTimes.isEmpty else {
      completion(.success(()))
      return
    }

    UNUserNotificationCenter.current().getNotificationSettings { settings in
      scheduleReminders(
        after: settings.authorizationStatus,
        for: calendar,
        reminderTimes: reminderTimes,
        store: store,
        completion: completion
      )
    }
  }
}

public func cancelNotifications(for calendar: CustomCalendar) {
  removePendingNotifications(for: calendar.id) {}
}

private func removePendingNotifications(for calendarId: UUID, completion: @escaping () -> Void) {
  UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    let identifiersToRemove = requests.compactMap { request -> String? in
      guard deriveCalendarId(from: request) == calendarId else {
        return nil
      }
      return request.identifier
    }

    if !identifiersToRemove.isEmpty {
      UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: identifiersToRemove
      )
    }

    completion()
  }
}

private func shouldScheduleNotifications(for calendar: CustomCalendar) -> Bool {
  !calendar.isAppleHealthConnected && !calendar.isArchived && calendar.recurringReminderEnabled
}

private func scheduleReminders(
  after authorizationStatus: UNAuthorizationStatus,
  for calendar: CustomCalendar,
  reminderTimes: [ReminderScheduleTime],
  store: CustomCalendarStore?,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  switch authorizationStatus {
  case .notDetermined:
    requestAuthorizationThenSchedule(
      for: calendar,
      reminderTimes: reminderTimes,
      store: store,
      completion: completion
    )
  case .authorized, .provisional:
    scheduleAuthorizedReminders(
      for: calendar,
      reminderTimes: reminderTimes,
      store: store,
      completion: completion
    )
  case .denied:
    completion(.failure(.permissionDenied))
  case .ephemeral:
    completion(.failure(.unsupportedMode))
  @unknown default:
    completion(.failure(.unknownStatus))
  }
}

private func requestAuthorizationThenSchedule(
  for calendar: CustomCalendar,
  reminderTimes: [ReminderScheduleTime],
  store: CustomCalendarStore?,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  UNUserNotificationCenter.current().requestAuthorization(
    options: [.alert, .sound, .badge]
  ) { granted, error in
    defer {
      NotificationCenter.default.post(name: .notificationAuthorizationChanged, object: nil)
    }

    if let error = error {
      completion(.failure(.schedulingFailed(error)))
    } else if granted {
      scheduleAuthorizedReminders(
        for: calendar,
        reminderTimes: reminderTimes,
        store: store,
        completion: completion
      )
    } else {
      completion(.failure(.permissionDenied))
    }
  }
}

private func scheduleAuthorizedReminders(
  for calendar: CustomCalendar,
  reminderTimes: [ReminderScheduleTime],
  store: CustomCalendarStore?,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  if let store {
    Task { @MainActor in
      scheduleStreakProtectionReminder(for: calendar, store: store)
    }
  }

  scheduleAllReminders(
    for: calendar,
    reminderTimes: reminderTimes,
    store: store,
    completion: completion
  )
}

private func scheduleAllReminders(
  for calendar: CustomCalendar,
  reminderTimes: [ReminderScheduleTime],
  store: CustomCalendarStore?,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  let group = DispatchGroup()
  let errorsQueue = DispatchQueue(label: "notifications.scheduleAllReminders.errors")
  var errors: [NotificationError] = []

  for reminderTime in reminderTimes {
    group.enter()
    scheduleReminder(for: calendar, reminderTime: reminderTime, store: store) { result in
      if case .failure(let error) = result {
        errorsQueue.sync {
          errors.append(error)
        }
      }
      group.leave()
    }
  }

  group.notify(queue: .main) {
    if let firstError = errorsQueue.sync(execute: { errors.first }) {
      completion(.failure(firstError))
    } else {
      completion(.success(()))
    }
  }
}

private func scheduleReminder(
  for calendar: CustomCalendar,
  reminderTime: ReminderScheduleTime,
  store: CustomCalendarStore?,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  let request = UNNotificationRequest(
    identifier: reminderTime.notificationId(for: calendar.id),
    content: makeReminderNotificationContent(for: calendar, dynamicContentEnabled: store != nil),
    trigger: reminderTrigger(for: calendar, reminderTime: reminderTime)
  )

  UNUserNotificationCenter.current().add(request) { error in
    if let error = error {
      NSLog("Failed to schedule notification for \(calendar.name): \(error)")
      completion(.failure(.schedulingFailed(error)))
    } else {
      completion(.success(()))
    }
  }
}

private func reminderTrigger(
  for calendar: CustomCalendar,
  reminderTime: ReminderScheduleTime
) -> UNCalendarNotificationTrigger {
  var components = DateComponents()
  components.hour = reminderTime.hour
  components.minute = reminderTime.minute
  if calendar.cadence == .weekly {
    components.weekday = calendar.reminderWeekday ?? Calendar.current.component(.weekday, from: Date())
  }
  components.timeZone = calendar.reminderTimeZone.flatMap(TimeZone.init(identifier:)) ?? .current

  return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
}
