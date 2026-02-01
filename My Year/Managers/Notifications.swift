import SharedModels
import UserNotifications

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
  print("✅ Notification categories configured")
}

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
  
  // Set category for quick actions
  content.categoryIdentifier = NotificationAction.categoryIdentifier
  
  // Store calendar ID for action handling
  content.userInfo = [
    "calendarId": calendar.id.uuidString,
    "calendarName": calendar.name
  ]
  
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

// MARK: - Notification Actions Handler

/// Handles notification action responses
/// - Parameters:
///   - response: The notification response
///   - store: The calendar store to perform actions on
public func handleNotificationAction(
  _ response: UNNotificationResponse,
  store: CustomCalendarStore
) {
  let userInfo = response.notification.request.content.userInfo
  
  guard let calendarIdString = userInfo["calendarId"] as? String,
        let calendarId = UUID(uuidString: calendarIdString),
        let calendar = store.calendars.first(where: { $0.id == calendarId }) else {
    print("❌ Invalid calendar ID in notification action")
    return
  }
  
  switch response.actionIdentifier {
  case NotificationAction.quickLog:
    handleQuickLog(for: calendar, store: store)
    
  case NotificationAction.snooze:
    handleSnooze(for: calendar)
    
  case UNNotificationDefaultActionIdentifier:
    // User tapped the notification - app will open to the calendar
    print("📱 User tapped notification for \(calendar.name)")
    
  default:
    break
  }
}

/// Quick log handler - logs an entry for today
private func handleQuickLog(for calendar: CustomCalendar, store: CustomCalendarStore) {
  let today = Date()
  
  // Create entry based on tracking type
  let entry: CalendarEntry
  switch calendar.trackingType {
  case .binary:
    entry = CalendarEntry(date: today, count: 1, completed: true)
    
  case .counter:
    let defaultValue = calendar.defaultRecordValue ?? 1
    entry = CalendarEntry(date: today, count: defaultValue, completed: false)
    
  case .multipleDaily:
    let currentCount = store.getEntry(calendarId: calendar.id, date: today)?.count ?? 0
    let newCount = currentCount + 1
    let completed = newCount >= calendar.dailyTarget
    entry = CalendarEntry(date: today, count: newCount, completed: completed)
  }
  
  store.addEntry(calendarId: calendar.id, entry: entry)
  print("✅ Quick logged entry for \(calendar.name)")
}

/// Snooze handler - reschedules notification for 1 hour later
private func handleSnooze(for calendar: CustomCalendar) {
  let notificationId = "\(calendar.id.uuidString)-snooze"
  let content = UNMutableNotificationContent()
  
  // Apply privacy mode
  switch calendar.notificationPrivacyMode {
  case .full:
    content.title = String(
      format: NSLocalizedString(
        "notification.snooze.title",
        value: "Reminder: %@",
        comment: "Snoozed notification title"
      ),
      calendar.name
    )
    content.body = NSLocalizedString(
      "notification.snooze.body",
      value: "Don't forget to log your habit!",
      comment: "Snoozed notification body"
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
  
  // Schedule for 1 hour from now
  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
  let request = UNNotificationRequest(
    identifier: notificationId,
    content: content,
    trigger: trigger
  )
  
  UNUserNotificationCenter.current().add(request) { error in
    if let error = error {
      print("❌ Failed to schedule snooze notification: \(error)")
    } else {
      print("⏰ Snoozed notification for \(calendar.name) for 1 hour")
    }
  }
}

// MARK: - Smart Suppression

/// Checks if a notification should be suppressed (entry already completed)
/// - Parameters:
///   - calendar: The calendar to check
///   - store: The calendar store
/// - Returns: True if notification should be suppressed
public func shouldSuppressNotification(for calendar: CustomCalendar, store: CustomCalendarStore) -> Bool {
  let today = Date()
  
  guard let entry = store.getEntry(calendarId: calendar.id, date: today) else {
    // No entry for today, show notification
    return false
  }
  
  // Check based on tracking type
  switch calendar.trackingType {
  case .binary:
    // Binary: suppress if completed
    return entry.completed
    
  case .counter:
    // Counter: suppress if any value has been logged
    return entry.count > 0
    
  case .multipleDaily:
    // Multiple daily: suppress if target reached
    return entry.count >= calendar.dailyTarget
  }
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
