import SharedModels
import UserNotifications

// MARK: - Notification Errors

public enum NotificationError: LocalizedError {
  case permissionDenied
  case permissionNotDetermined
  case unsupportedMode
  case unknownStatus
  case schedulingFailed(Error)
  case invalidCalendarData
  
  public var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return NSLocalizedString(
        "notification.error.permission_denied",
        value: "Notification permissions are required. Please enable them in Settings.",
        comment: "Error when notification permissions are denied"
      )
    case .permissionNotDetermined:
      return NSLocalizedString(
        "notification.error.permission_not_determined",
        value: "Notification permissions need to be granted.",
        comment: "Error when notification permissions haven't been requested yet"
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
    case .invalidCalendarData:
      return NSLocalizedString(
        "notification.error.invalid_data",
        value: "Invalid calendar data for notification scheduling.",
        comment: "Error when calendar data is invalid"
      )
    }
  }
}

// MARK: - Notification Scheduling

/// Schedules notifications for a calendar with proper error handling and permission checks
/// - Parameters:
///   - calendar: The calendar to schedule notifications for
///   - completion: Completion handler called with result (success or error)
public func scheduleNotifications(
  for calendar: CustomCalendar,
  completion: @escaping (Result<Void, NotificationError>) -> Void = { _ in }
) {
  let notificationId = calendar.id.uuidString
  
  // First, always remove existing notifications to prevent duplicates
  UNUserNotificationCenter.current().removePendingNotificationRequests(
    withIdentifiers: [notificationId]
  )
  
  // If calendar is archived or reminder disabled, we're done (already removed)
  guard !calendar.isArchived,
        calendar.recurringReminderEnabled,
        let hour = calendar.reminderHour,
        let minute = calendar.reminderMinute else {
    completion(.success(()))
    return
  }
  
  // Check notification permissions before scheduling
  UNUserNotificationCenter.current().getNotificationSettings { settings in
    switch settings.authorizationStatus {
    case .notDetermined:
      // Request permission first
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound, .badge]
      ) { granted, error in
        if let error = error {
          completion(.failure(.schedulingFailed(error)))
        } else if granted {
          _scheduleNotificationInternal(
            for: calendar,
            hour: hour,
            minute: minute,
            completion: completion
          )
        } else {
          completion(.failure(.permissionDenied))
        }
      }
      
    case .authorized, .provisional:
      _scheduleNotificationInternal(
        for: calendar,
        hour: hour,
        minute: minute,
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
}

/// Internal function to actually schedule the notification after permission checks
private func _scheduleNotificationInternal(
  for calendar: CustomCalendar,
  hour: Int,
  minute: Int,
  completion: @escaping (Result<Void, NotificationError>) -> Void
) {
  let notificationId = calendar.id.uuidString
  let content = UNMutableNotificationContent()
  
  // Apply privacy mode settings
  switch calendar.notificationPrivacyMode {
  case .full:
    content.title = String(
      format: NSLocalizedString(
        "notification.reminder.title",
        value: "Time to log %@",
        comment: "Notification title for calendar reminder"
      ),
      calendar.name
    )
    content.body = String(
      format: NSLocalizedString(
        "notification.reminder.body",
        value: "Don't forget to track %@ today! (Target: %d)",
        comment: "Notification body for calendar reminder"
      ),
      calendar.name,
      calendar.dailyTarget
    )
    
  case .generic:
    content.title = NSLocalizedString(
      "notification.reminder.generic.title",
      value: "Habit Reminder",
      comment: "Generic notification title"
    )
    content.body = NSLocalizedString(
      "notification.reminder.generic.body",
      value: "Time to log your daily habit",
      comment: "Generic notification body"
    )
    
  case .hidden:
    // No text, just badge and sound
    content.badge = NSNumber(value: 1)
    content.title = ""
    content.body = ""
  }
  
  content.sound = .default
  
  // Set up timezone-aware trigger
  var components = DateComponents()
  components.hour = hour
  components.minute = minute
  
  // Use stored timezone if available, otherwise current
  if let timeZoneIdentifier = calendar.reminderTimeZone,
     let timeZone = TimeZone(identifier: timeZoneIdentifier) {
    components.timeZone = timeZone
  } else {
    components.timeZone = TimeZone.current
  }
  
  let trigger = UNCalendarNotificationTrigger(
    dateMatching: components,
    repeats: true
  )
  
  let request = UNNotificationRequest(
    identifier: notificationId,
    content: content,
    trigger: trigger
  )
  
  UNUserNotificationCenter.current().add(request) { error in
    if let error = error {
      print("❌ Failed to schedule notification for \(calendar.name): \(error)")
      completion(.failure(.schedulingFailed(error)))
    } else {
      print("✅ Scheduled notification for \(calendar.name) at \(hour):\(String(format: "%02d", minute))")
      completion(.success(()))
    }
  }
}

// MARK: - Notification Cancellation

/// Cancels all pending notifications for a calendar
/// - Parameter calendar: The calendar whose notifications should be cancelled
public func cancelNotifications(for calendar: CustomCalendar) {
  UNUserNotificationCenter.current().removePendingNotificationRequests(
    withIdentifiers: [calendar.id.uuidString]
  )
  print("🗑️ Cancelled notifications for \(calendar.name)")
}

// MARK: - Notification Cleanup

/// Removes notifications for calendars that no longer exist
/// - Parameter store: The calendar store to check against
public func checkForNotificationsOfNonExistingCalendars(store: CustomCalendarStore) async {
  let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
  let calendarIds = Set(store.calendars.map { $0.id.uuidString })
  
  var removedCount = 0
  for request in requests {
    if !calendarIds.contains(request.identifier) {
      print("🧹 Found notification for non-existing calendar: \(request.identifier)")
      UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: [request.identifier]
      )
      removedCount += 1
    }
  }
  
  if removedCount > 0 {
    print("✨ Cleaned up \(removedCount) orphaned notification(s)")
  }
}

// MARK: - Validation (Legacy - preserved for compatibility)

/// Validates and adjusts reminder time (LEGACY - not actively used)
/// - Parameter time: The time to validate
/// - Returns: Adjusted time if original was in the past
@available(*, deprecated, message: "This function is not actively used and has known issues")
public func validateReminderTime(_ time: Date) -> Date {
  let calendar = Calendar.current
  let now = Date()
  
  // If the absolute date is in the past, shift forward
  if time < now {
    let targetComponents = calendar.dateComponents([.hour, .minute], from: time)
    
    // Find the next occurrence of this time
    if let nextOccurrence = calendar.nextDate(
      after: now,
      matching: targetComponents,
      matchingPolicy: .nextTime
    ) {
      return nextOccurrence
    }
  }
  
  return time
}

// MARK: - Permission Helpers

/// Checks if notification permissions are granted
/// - Parameter completion: Completion handler with boolean result
public func checkNotificationPermissions(
  completion: @escaping (Bool) -> Void
) {
  UNUserNotificationCenter.current().getNotificationSettings { settings in
    let isAuthorized = settings.authorizationStatus == .authorized ||
                      settings.authorizationStatus == .provisional
    completion(isAuthorized)
  }
}

/// Requests notification permissions if not already granted
/// - Parameter completion: Completion handler with result
public func requestNotificationPermissions(
  completion: @escaping (Result<Bool, Error>) -> Void
) {
  UNUserNotificationCenter.current().getNotificationSettings { settings in
    switch settings.authorizationStatus {
    case .notDetermined:
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound, .badge]
      ) { granted, error in
        if let error = error {
          completion(.failure(error))
        } else {
          completion(.success(granted))
        }
      }
      
    case .authorized, .provisional:
      completion(.success(true))
      
    default:
      completion(.success(false))
    }
  }
}
