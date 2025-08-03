import SharedModels
import UserNotifications

func scheduleNotifications(for calendar: CustomCalendar) {
  guard calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
    let minute = calendar.reminderMinute
  else {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      calendar.id.uuidString
    ])
    return
  }

  let content = UNMutableNotificationContent()
  content.title = String(
    format: NSLocalizedString(
      "notification.reminder.title", comment: "Notification title for calendar reminder"),
    calendar.name)
  content.body = String(
    format: NSLocalizedString(
      "notification.reminder.body", comment: "Notification body for calendar reminder"),
    calendar.name, calendar.dailyTarget)
  content.sound = .default

  let components = DateComponents(hour: hour, minute: minute)
  let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

  let request = UNNotificationRequest(
    identifier: calendar.id.uuidString, content: content, trigger: trigger)
  UNUserNotificationCenter.current().add(request) { error in
    if let error = error {
      print("Error scheduling notification: \(error)")
    }
  }
}

func cancelNotifications(for calendar: CustomCalendar) {
  UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
    calendar.id.uuidString
  ])
}

func checkForNotificationsOfNonExistingCalendars(store: CustomCalendarStore) async {
  let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
  for request in requests {
    if !store.calendars.contains(where: { $0.id.uuidString == request.identifier }) {
      print("Found notification for non-existing calendar: \(request.identifier)")
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        request.identifier
      ])
      print("Removed notification for non-existing calendar: \(request.identifier)")
    }
  }
}

func validateReminderTime(_ time: Date) -> Date {
  let calendar = Calendar.current
  let now = Date()

  // Extract hour and minute components
  let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
  let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

  // If time is in the past for today, set it for tomorrow
  if timeComponents.hour! < nowComponents.hour!
    || (timeComponents.hour! == nowComponents.hour!
      && timeComponents.minute! <= nowComponents.minute!)
  {
    return calendar.date(byAdding: .day, value: 1, to: time)!
  }
  return time
}
