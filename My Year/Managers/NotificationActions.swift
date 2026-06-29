import Foundation
@preconcurrency import SharedModels
import UserNotifications

// MARK: - Notification Actions Handler

/// Handles notification action responses
/// - Parameters:
///   - response: The notification response
///   - store: The calendar store to perform actions on
@MainActor
public func handleNotificationAction(
    _ response: UNNotificationResponse,
    store: CustomCalendarStore
) {
    let userInfo = response.notification.request.content.userInfo
    guard let calendarIdString = userInfo["calendarId"] as? String,
          let calendarId = UUID(uuidString: calendarIdString),
          let calendar = calendarForNotificationAction(id: calendarId, store: store)
    else {
        NSLog("Invalid calendar ID in notification action")
        return
    }

    switch response.actionIdentifier {
    case NotificationAction.quickLog:
        handleQuickLog(for: calendar, store: store)

    case NotificationAction.snooze:
        handleSnooze(for: calendar)

    default:
        break
    }
}

@MainActor
private func calendarForNotificationAction(
    id calendarId: UUID,
    store: CustomCalendarStore
) -> CustomCalendar? {
    store.snapshot.calendar(id: calendarId)
        ?? CustomCalendarStore.fetchCalendarsSnapshot().first { $0.id == calendarId }
}

/// Quick log handler - logs an entry for today
@MainActor
private func handleQuickLog(for calendar: CustomCalendar, store: CustomCalendarStore) {
    do {
      _ = try CalendarShortcutService.checkIn(
        calendar: calendar,
        date: Date(),
        value: nil,
        store: store,
        source: .notification
      )
    } catch {
      NSLog("Failed to quick log from notification: \(error)")
    }
}

/// Snooze handler - reschedules notification for 1 hour later
private func handleSnooze(for calendar: CustomCalendar) {
    let notificationId = "\(calendar.id.uuidString)-snooze"
    let content = snoozeContent(for: calendar)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
    let request = UNNotificationRequest(
        identifier: notificationId,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            NSLog("Failed to schedule snooze notification: \(error)")
        }
    }
}

private func snoozeContent(for calendar: CustomCalendar) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    switch calendar.notificationPrivacyMode {
    case .full:
        let titleFormat = NSLocalizedString(
            "notification.snooze.title.full",
            value: "Reminder: %@",
            comment: "Snoozed notification title with habit name"
        )
        content.title = String(format: titleFormat, calendar.name)
        content.body = calendar.cadence == .weekly
            ? String(localized: "Don't forget to log your habit this week!")
            : NSLocalizedString(
                "notification.snooze.body.full",
                value: "Don't forget to log your habit!",
                comment: "Snoozed notification body"
            )

    case .generic:
        content.title = NSLocalizedString(
            "notification.reminder.title.generic",
            value: "Habit Reminder",
            comment: "Generic notification title"
        )
        content.body = NSLocalizedString(
            "notification.reminder.body.generic",
            value: "Time to log your daily habit",
            comment: "Generic notification body"
        )
        if calendar.cadence == .weekly {
            content.body = String(localized: "Time to log your habit this week")
        }

    case .hidden:
        content.badge = NSNumber(value: 1)
        content.title = ""
        content.body = ""
    }

    content.sound = .default
    content.categoryIdentifier = NotificationAction.categoryIdentifier
    content.userInfo = [
        "calendarId": calendar.id.uuidString,
        "calendarName": calendar.name
    ]

    return content
}
