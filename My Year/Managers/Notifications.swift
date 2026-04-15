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
        case let .schedulingFailed(error):
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

// MARK: - Reminder Content

private func makeReminderContent(
    for calendar: CustomCalendar,
    weekday: Int?,
    isPrimary: Bool
) -> (title: String, body: String) {
    switch calendar.notificationPrivacyMode {
    case .full:
        let titleFormat = NSLocalizedString(
            "notification.reminder.title.full",
            value: "Time to log %@",
            comment: "Notification title with habit name"
        )
        let title = String(format: titleFormat, calendar.name)
        let bodyFormat = fullReminderBodyFormat(weekday: weekday, isPrimary: isPrimary)
        return (title, String(format: bodyFormat, calendar.name))

    case .generic:
        let title = NSLocalizedString(
            "notification.reminder.title.generic",
            value: "Habit Reminder",
            comment: "Generic notification title"
        )
        return (title, genericReminderBody(weekday: weekday, isPrimary: isPrimary))

    case .hidden:
        return ("", "")
    }
}

private func fullReminderBodyFormat(weekday: Int?, isPrimary: Bool) -> String {
    guard isPrimary, let weekday else {
        return NSLocalizedString(
            "notification.reminder.additional.full",
            value: "Quick check-in: log %@.",
            comment: "Additional reminder body with habit name"
        )
    }

    switch weekday {
    case 1:
        return NSLocalizedString(
            "notification.reminder.primary.sunday.full",
            value: "End the week with clean data. Update %@.",
            comment: "Sunday primary reminder body with habit name"
        )
    case 2:
        return NSLocalizedString(
            "notification.reminder.primary.monday.full",
            value: "Start the week clean. Log %@.",
            comment: "Monday primary reminder body with habit name"
        )
    case 3:
        return NSLocalizedString(
            "notification.reminder.primary.tuesday.full",
            value: "Tiny check-in. Record %@.",
            comment: "Tuesday primary reminder body with habit name"
        )
    case 4:
        return NSLocalizedString(
            "notification.reminder.primary.wednesday.full",
            value: "Midweek data point: update %@.",
            comment: "Wednesday primary reminder body with habit name"
        )
    case 5:
        return NSLocalizedString(
            "notification.reminder.primary.thursday.full",
            value: "Keep the signal alive. Log %@.",
            comment: "Thursday primary reminder body with habit name"
        )
    case 6:
        return NSLocalizedString(
            "notification.reminder.primary.friday.full",
            value: "Close the loop before the weekend. Record %@.",
            comment: "Friday primary reminder body with habit name"
        )
    case 7:
        return NSLocalizedString(
            "notification.reminder.primary.saturday.full",
            value: "Still counts today. Log %@.",
            comment: "Saturday primary reminder body with habit name"
        )
    default:
        return NSLocalizedString(
            "notification.reminder.additional.full",
            value: "Quick check-in: log %@.",
            comment: "Fallback reminder body with habit name"
        )
    }
}

private func genericReminderBody(weekday: Int?, isPrimary: Bool) -> String {
    guard isPrimary, let weekday else {
        return NSLocalizedString(
            "notification.reminder.additional.generic",
            value: "Quick check-in. Log your habit.",
            comment: "Additional generic reminder body"
        )
    }

    switch weekday {
    case 1:
        return NSLocalizedString(
            "notification.reminder.primary.sunday.generic",
            value: "End the week with clean data.",
            comment: "Sunday primary generic reminder body"
        )
    case 2:
        return NSLocalizedString(
            "notification.reminder.primary.monday.generic",
            value: "Start the week clean. Log your habit.",
            comment: "Monday primary generic reminder body"
        )
    case 3:
        return NSLocalizedString(
            "notification.reminder.primary.tuesday.generic",
            value: "Tiny check-in. Record today's progress.",
            comment: "Tuesday primary generic reminder body"
        )
    case 4:
        return NSLocalizedString(
            "notification.reminder.primary.wednesday.generic",
            value: "Midweek data point.",
            comment: "Wednesday primary generic reminder body"
        )
    case 5:
        return NSLocalizedString(
            "notification.reminder.primary.thursday.generic",
            value: "Keep the signal alive.",
            comment: "Thursday primary generic reminder body"
        )
    case 6:
        return NSLocalizedString(
            "notification.reminder.primary.friday.generic",
            value: "Close the loop before the weekend.",
            comment: "Friday primary generic reminder body"
        )
    case 7:
        return NSLocalizedString(
            "notification.reminder.primary.saturday.generic",
            value: "Still counts today.",
            comment: "Saturday primary generic reminder body"
        )
    default:
        return NSLocalizedString(
            "notification.reminder.additional.generic",
            value: "Quick check-in. Log your habit.",
            comment: "Fallback generic reminder body"
        )
    }
}

/// Helper to determine if an entry counts as "success"
private func isEntrySuccess(entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
    isEntryFulfilledForNotification(entry, calendar: calendar)
}

/// Unified fulfillment check for notification logic.
/// Keeps suppression and streak/content calculations aligned.
func isEntryFulfilledForNotification(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
    switch calendar.trackingType {
    case .binary:
        return entry.completed
    case .counter:
        return entry.count > 0
    case .multipleDaily:
        return entry.count >= calendar.dailyTarget
    }
}

// MARK: - Request ID Utilities

/// Best-effort derivation of the calendar id a notification request belongs to.
/// We prefer `userInfo["calendarId"]` since request identifiers may include suffixes
/// (e.g. `-0`, `-streak-protection`, `-snooze`).
func deriveCalendarId(notificationIdentifier: String, userInfoCalendarId: String?) -> UUID? {
    if let userInfoCalendarId,
       let calendarId = UUID(uuidString: userInfoCalendarId)
    {
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

private func deriveCalendarId(from request: UNNotificationRequest) -> UUID? {
    deriveCalendarId(
        notificationIdentifier: request.identifier,
        userInfoCalendarId: request.content.userInfo["calendarId"] as? String
    )
}

private let streakProtectionIdentifierSuffix = "-streak-protection"

private func removePendingNotifications(for calendarId: UUID, completion: @escaping () -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        let identifiersToRemove = requests.compactMap { request -> String? in
            guard deriveCalendarId(from: request) == calendarId else {
                return nil
            }
            return request.identifier
        }

        if !identifiersToRemove.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }

        completion()
    }
}

private func removeAllPendingStreakProtectionNotifications(completion: @escaping () -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        let identifiersToRemove = requests.compactMap { request -> String? in
            request.identifier.hasSuffix(streakProtectionIdentifierSuffix) ? request.identifier : nil
        }

        if !identifiersToRemove.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }

        completion()
    }
}

// MARK: - Streak Protection

/// Schedules a streak protection reminder for late in the day
/// - Parameters:
///   - calendar: The calendar to protect
///   - store: Calendar store for streak calculation
public func scheduleStreakProtectionReminder(
    for calendar: CustomCalendar,
    store: CustomCalendarStore
) {
    let notificationId = "\(calendar.id.uuidString)\(streakProtectionIdentifierSuffix)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])

    let resolvedCalendar = calendar

    // Only schedule if enabled and reminders are on
    guard resolvedCalendar.streakProtectionEnabled,
          resolvedCalendar.recurringReminderEnabled
    else {
        return
    }

    // If today is already fulfilled, there is no streak risk.
    if let todayEntry = store.getEntry(calendarId: resolvedCalendar.id, date: Date()),
       isEntryFulfilledForNotification(todayEntry, calendar: resolvedCalendar)
    {
        return
    }

    // Calculate streak ending yesterday (the one at risk if today is missed).
    let streakAtRisk = calculateStreakEndingYesterday(for: resolvedCalendar)

    // Only protect significant streaks.
    guard streakAtRisk >= resolvedCalendar.streakProtectionThreshold else {
        return
    }

    // Schedule notification for 9 PM today
    let now = Date()
    let calendar_swift = Calendar.current
    guard let ninePM = calendar_swift.date(bySettingHour: 21, minute: 0, second: 0, of: now) else {
        return
    }

    // Only schedule if 9 PM is in the future
    guard ninePM > now else {
        return
    }

    let content = UNMutableNotificationContent()

    // Urgent, streak-focused copy
    switch resolvedCalendar.notificationPrivacyMode {
    case .full:
        content.title = String(
            format: String(localized: "🔥 Don't break your %lld-day streak!"),
            streakAtRisk
        )
        content.body = String(
            format: String(localized: "Quick! Log %@ before midnight"),
            resolvedCalendar.name
        )

    case .generic:
        content.title = String(localized: "🔥 Streak at risk!")
        content.body = String(localized: "Don't forget to log your habit today")

    case .hidden:
        content.badge = NSNumber(value: 1)
        content.title = ""
        content.body = ""
    }

    content.sound = .default
    content.categoryIdentifier = NotificationAction.categoryIdentifier
    content.userInfo = [
        "calendarId": resolvedCalendar.id.uuidString,
        "calendarName": resolvedCalendar.name,
        "isStreakProtection": true,
    ]

    // Schedule for 9 PM today (one-time, not recurring)
    let triggerDate = calendar_swift.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: ninePM
    )
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: triggerDate,
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: notificationId,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("❌ Failed to schedule streak protection: \(error)")
        } else {
            print("🛡️ Scheduled streak protection for \(resolvedCalendar.name) at 9 PM (\(streakAtRisk)-day streak)")
        }
    }
}

/// Refreshes one-time streak protection reminders for all calendars.
/// Call on app launch / app active to re-evaluate daily streak risk.
public func refreshStreakProtectionReminders(store: CustomCalendarStore) {
    removeAllPendingStreakProtectionNotifications {
        DispatchQueue.main.async {
            for calendar in store.calendars where !calendar.isArchived {
                scheduleStreakProtectionReminder(for: calendar, store: store)
            }
        }
    }
}

/// Calculates consecutive fulfilled days ending at yesterday.
private func calculateStreakEndingYesterday(for calendar: CustomCalendar) -> Int {
    let formatter = DayKeyFormatter.shared
    let dayCalendar = LocalDayCalendar.calendar
    guard let startDate = dayCalendar.date(byAdding: .day, value: -1, to: LocalDayCalendar.startOfDay(for: Date())) else {
        return 0
    }

    var streak = 0
    var checkDate = startDate

    for _ in 0 ..< 365 {
        let dayKey = formatter.string(from: checkDate)
        guard let entry = calendar.entries[dayKey],
              isEntrySuccess(entry: entry, calendar: calendar)
        else {
            break
        }
        streak += 1
        checkDate = dayCalendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
    }

    return streak
}

// MARK: - Notification Scheduling

/// Schedules notifications for a calendar with proper error handling and permission checks
/// - Parameters:
///   - calendar: The calendar to schedule notifications for
///   - store: Optional calendar store for dynamic content
///   - completion: Completion handler called with result (success or error)
public func scheduleNotifications(
    for calendar: CustomCalendar,
    store: CustomCalendarStore? = nil,
    completion: @escaping (Result<Void, NotificationError>) -> Void = { _ in }
) {
    removePendingNotifications(for: calendar.id) {
        // If calendar is archived or reminder disabled, we're done (already removed)
        guard !calendar.isArchived,
              calendar.recurringReminderEnabled
        else {
            completion(.success(()))
            return
        }

        // Collect all reminder times (primary + additional)
        var allReminderTimes: [(hour: Int, minute: Int, isPrimary: Bool)] = []
        if let hour = calendar.reminderHour, let minute = calendar.reminderMinute {
            allReminderTimes.append((hour, minute, true))
        }
        for reminderTime in calendar.additionalReminderTimes {
            allReminderTimes.append((reminderTime.hour, reminderTime.minute, false))
        }

        // If no reminder times configured, nothing to schedule
        guard !allReminderTimes.isEmpty else {
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
                        // Schedule streak protection if store available
                        if let store = store {
                            scheduleStreakProtectionReminder(for: calendar, store: store)
                        }

                        _scheduleAllReminders(
                            for: calendar,
                            reminderTimes: allReminderTimes,
                            completion: completion
                        )
                    } else {
                        completion(.failure(.permissionDenied))
                    }
                }

            case .authorized, .provisional:
                // Schedule streak protection if store available
                if let store = store {
                    scheduleStreakProtectionReminder(for: calendar, store: store)
                }

                _scheduleAllReminders(
                    for: calendar,
                    reminderTimes: allReminderTimes,
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
}

/// Schedule all reminder times for a calendar
private func _scheduleAllReminders(
    for calendar: CustomCalendar,
    reminderTimes: [(hour: Int, minute: Int, isPrimary: Bool)],
    completion: @escaping (Result<Void, NotificationError>) -> Void
) {
    let group = DispatchGroup()
    let errorsQueue = DispatchQueue(label: "notification-scheduling-errors")
    var errors: [Error] = []

    var additionalIndex = 0
    for reminderTime in reminderTimes {
        if reminderTime.isPrimary {
            for weekday in 1 ... 7 {
                group.enter()
                _scheduleNotificationInternal(
                    for: calendar,
                    notificationId: "\(calendar.id.uuidString)-primary-\(weekday)",
                    hour: reminderTime.hour,
                    minute: reminderTime.minute,
                    weekday: weekday,
                    isPrimary: true
                ) { result in
                    if case let .failure(error) = result {
                        errorsQueue.sync {
                            errors.append(error)
                        }
                    }
                    group.leave()
                }
            }
        } else {
            group.enter()
            let notificationId = "\(calendar.id.uuidString)-\(additionalIndex)"
            additionalIndex += 1

            _scheduleNotificationInternal(
                for: calendar,
                notificationId: notificationId,
                hour: reminderTime.hour,
                minute: reminderTime.minute,
                weekday: nil,
                isPrimary: false
            ) { result in
                if case let .failure(error) = result {
                    errorsQueue.sync {
                        errors.append(error)
                    }
                }
                group.leave()
            }
        }
    }

    group.notify(queue: .main) {
        let firstError = errorsQueue.sync {
            errors.first as? NotificationError
        }
        if let firstError {
            completion(.failure(firstError))
        } else {
            completion(.success(()))
        }
    }
}

/// Internal function to actually schedule the notification after permission checks
private func _scheduleNotificationInternal(
    for calendar: CustomCalendar,
    notificationId: String,
    hour: Int,
    minute: Int,
    weekday: Int?,
    isPrimary: Bool,
    completion: @escaping (Result<Void, NotificationError>) -> Void
) {
    let content = UNMutableNotificationContent()

    let reminderContent = makeReminderContent(for: calendar, weekday: weekday, isPrimary: isPrimary)
    content.title = reminderContent.title
    content.body = reminderContent.body
    if calendar.notificationPrivacyMode == .hidden {
        content.badge = NSNumber(value: 1)
    }

    content.sound = .default

    // Set category for quick actions
    content.categoryIdentifier = NotificationAction.categoryIdentifier

    // Store calendar ID for action handling
    content.userInfo = [
        "calendarId": calendar.id.uuidString,
        "calendarName": calendar.name,
    ]

    // Set up timezone-aware trigger
    var components = DateComponents()
    components.weekday = weekday
    components.hour = hour
    components.minute = minute

    // Use stored timezone if available, otherwise current
    if let timeZoneIdentifier = calendar.reminderTimeZone,
       let timeZone = TimeZone(identifier: timeZoneIdentifier)
    {
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
    removePendingNotifications(for: calendar.id) {
        print("🗑️ Cancelled notifications for \(calendar.name)")
    }
}

// MARK: - Notification Cleanup

/// Removes notifications for calendars that no longer exist
/// - Parameter store: The calendar store to check against
public func checkForNotificationsOfNonExistingCalendars(store: CustomCalendarStore) async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let calendarIds = Set(store.calendars.map { $0.id.uuidString })

    var removedCount = 0
    for request in requests {
        guard let requestCalendarId = deriveCalendarId(from: request) else {
            // Not ours or malformed; ignore.
            continue
        }

        if !calendarIds.contains(requestCalendarId.uuidString) {
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
          let calendar = store.calendars.first(where: { $0.id == calendarId })
    else {
        print("❌ Invalid calendar ID in notification action")
        return
    }

    switch response.actionIdentifier {
    case NotificationAction.quickLog:
        handleQuickLog(for: calendar, store: store)

    case NotificationAction.snooze:
        handleSnooze(for: calendar)

    case UNNotificationDefaultActionIdentifier:
        // Note: Default tap action (opening calendar) is handled in AppDelegate
        // via deep link: my-year://calendar/<id>
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

    // Apply privacy mode with localization
    switch calendar.notificationPrivacyMode {
    case .full:
        // Show full habit details in snoozed notification
        let titleFormat = NSLocalizedString(
            "notification.snooze.title.full",
            value: "Reminder: %@",
            comment: "Snoozed notification title with habit name"
        )
        content.title = String(format: titleFormat, calendar.name)
        content.body = NSLocalizedString(
            "notification.snooze.body.full",
            value: "Don't forget to log your habit!",
            comment: "Snoozed notification body"
        )

    case .generic:
        // Show generic message for privacy
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

    case .hidden:
        content.badge = NSNumber(value: 1)
        content.title = ""
        content.body = ""
    }

    content.sound = .default
    content.categoryIdentifier = NotificationAction.categoryIdentifier
    content.userInfo = [
        "calendarId": calendar.id.uuidString,
        "calendarName": calendar.name,
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
        #if DEBUG
            print(
                "🔎 Notification suppression decision: calendarId=\(calendar.id.uuidString) "
                    + "trackingType=\(calendar.trackingType) entryCount=nil entryCompleted=nil suppress=false"
            )
        #endif
        // No entry for today, show notification
        return false
    }

    let shouldSuppress = isEntryFulfilledForNotification(entry, calendar: calendar)

    #if DEBUG
        print(
            "🔎 Notification suppression decision: calendarId=\(calendar.id.uuidString) "
                + "trackingType=\(calendar.trackingType) entryCount=\(entry.count) "
                + "entryCompleted=\(entry.completed) suppress=\(shouldSuppress)"
        )
    #endif

    return shouldSuppress
}

// MARK: - Permission Helpers

/// Checks if notification permissions are granted
/// - Parameter completion: Completion handler with boolean result
public func checkNotificationPermissions(
    completion: @escaping (Bool) -> Void
) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
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
