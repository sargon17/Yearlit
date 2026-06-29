import Foundation
@preconcurrency import SharedModels
import UserNotifications

extension Notification.Name {
  static let notificationAuthorizationChanged = Notification.Name("notificationAuthorizationChanged")
}

// MARK: - Notification Action Identifiers

public enum NotificationAction {
  public static let quickLog = "QUICK_LOG_ACTION"
  public static let snooze = "SNOOZE_ACTION"
  public static let categoryIdentifier = "HABIT_REMINDER"
}

// MARK: - Notification Categories Setup

/// Sets up notification categories with quick actions
/// Should be called once during app initialization
public func setupNotificationCategories() {
  let quickLogAction = UNNotificationAction(
    identifier: NotificationAction.quickLog,
    title: NSLocalizedString(
      "notification.action.log",
      value: "Log Now",
      comment: "Quick action to log habit from notification"
    ),
    options: [.foreground]
  )

  let snoozeAction = UNNotificationAction(
    identifier: NotificationAction.snooze,
    title: NSLocalizedString(
      "notification.action.snooze",
      value: "Remind me in 1 hour",
      comment: "Quick action to snooze notification"
    ),
    options: []
  )

  let category = UNNotificationCategory(
    identifier: NotificationAction.categoryIdentifier,
    actions: [quickLogAction, snoozeAction],
    intentIdentifiers: [],
    options: []
  )

  UNUserNotificationCenter.current().setNotificationCategories([category])
}

// MARK: - Notification Errors

public enum NotificationError: LocalizedError {
  case permissionDenied
  case unsupportedMode
  case unknownStatus
  case schedulingFailed(Error)

  public var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return NSLocalizedString(
        "notification.error.permission_denied",
        value: "Notification permissions are required. Please enable them in Settings.",
        comment: "Error when notification permissions are denied"
      )
    case .unsupportedMode:
      return NSLocalizedString(
        "notification.error.unsupported_mode",
        value: "Notifications are not supported in this mode.",
        comment: "Error when notification mode is unsupported"
      )
    case .unknownStatus:
      return NSLocalizedString(
        "notification.error.unknown_status",
        value: "Unable to determine notification status.",
        comment: "Error when notification status cannot be determined"
      )
    case .schedulingFailed(let error):
      return String(
        format: NSLocalizedString(
          "notification.error.scheduling_failed",
          value: "Failed to schedule notification: %@",
          comment: "Error when scheduling fails"
        ),
        error.localizedDescription
      )
    }
  }
}

func isEntryFulfilledForNotification(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
  switch calendar.trackingType {
  case .binary:
    return entry.completed
  case .counter:
    return entry.count >= 1
  case .multipleDaily:
    return entry.count >= calendar.dailyTarget
  }
}

func deriveCalendarId(notificationIdentifier: String, userInfoCalendarId: String?) -> UUID? {
  if let userInfoCalendarId, let calendarId = UUID(uuidString: userInfoCalendarId) {
    return calendarId
  }

  if let calendarId = UUID(uuidString: notificationIdentifier) {
    return calendarId
  }

  // All of our derived identifiers are prefixed with the 36-char UUID string.
  guard notificationIdentifier.count >= 36 else {
    return nil
  }
  return UUID(uuidString: String(notificationIdentifier.prefix(36)))
}

func deriveCalendarId(from request: UNNotificationRequest) -> UUID? {
  deriveCalendarId(
    notificationIdentifier: request.identifier,
    userInfoCalendarId: request.content.userInfo["calendarId"] as? String
  )
}
