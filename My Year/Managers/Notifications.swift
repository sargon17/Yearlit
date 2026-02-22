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

// MARK: - Dynamic Notification Content

/// Generates dynamic, motivational notification content based on calendar progress
/// - Parameters:
///   - calendar: The calendar to generate content for
///   - store: The calendar store for accessing stats
/// - Returns: Tuple of (title, body) with motivational content
private func generateDynamicContent(
    for calendar: CustomCalendar,
    store: CustomCalendarStore
) -> (title: String, body: String) {
    let stats = calculateStreakStats(for: calendar, store: store)

    // Base title
    let titleFormat = NSLocalizedString(
        "notification.reminder.title.full",
        value: "Time to log %@",
        comment: "Notification title with habit name"
    )
    let title = String(format: titleFormat, calendar.name)

    // Dynamic body based on streak and progress
    var body: String

    if stats.currentStreak >= 7 {
        // Long streak - emphasize maintenance
        let messages = [
            String(
                format: String(localized: "🔥 You're on a %lld-day streak! Keep it alive!"),
                stats.currentStreak
            ),
            String(
                format: String(localized: "💪 %lld days strong! Don't break it now!"),
                stats.currentStreak
            ),
            String(
                format: String(localized: "✨ Amazing! %lld days in a row. One more today!"),
                stats.currentStreak
            ),
        ]
        body = messages.randomElement() ?? messages[0]

    } else if stats.currentStreak >= 3 {
        // Building momentum
        let messages = [
            String(
                format: String(localized: "%lld days down! You're building momentum 🚀"),
                stats.currentStreak
            ),
            String(
                format: String(localized: "Day %lld of your streak! Keep going 💪"),
                stats.currentStreak
            ),
            String(
                format: String(localized: "Nice! %lld in a row. Let's make it %lld!"),
                stats.currentStreak,
                stats.currentStreak + 1
            ),
        ]
        body = messages.randomElement() ?? messages[0]

    } else if stats.completedYesterday {
        // Did it yesterday, encourage continuation
        let messages = [
            String(localized: "Great job yesterday! Let's keep it going today 🎯"),
            String(localized: "You did it yesterday, you can do it today! 💚"),
            String(localized: "Yesterday ✅ Today? Let's go! 🔥"),
        ]
        body = messages.randomElement() ?? messages[0]

    } else if stats.weeklyCompletionRate > 0.7 {
        // Good weekly progress
        let weekPercent = Int(stats.weeklyCompletionRate * 100)
        body = String(
            format: String(localized: "You're at %lld%% this week! Keep pushing 💪"),
            weekPercent
        )

    } else {
        // Default motivational message
        let messages = [
            String(
                format: String(localized: "Time to build your habit! (Target: %lld)"),
                calendar.dailyTarget
            ),
            String(localized: "Every day counts! Log your progress today 📊"),
            String(
                format: String(localized: "Small steps, big results. Let's track %@! 🎯"),
                calendar.name
            ),
        ]
        body = messages.randomElement() ?? messages[0]
    }

    return (title, body)
}

/// Calculate streak statistics for a calendar
private func calculateStreakStats(
    for calendar: CustomCalendar,
    store _: CustomCalendarStore
) -> StreakStats {
    var currentStreak = 0
    var weeklyCompleted = 0

    let dayCalendar = LocalDayCalendar.calendar
    let dateFormatter = DayKeyFormatter.shared
    let today = LocalDayCalendar.startOfDay(for: Date())

    // Current streak: consecutive fulfilled days from today backwards.
    var streakDate = today
    for _ in 0 ..< 365 {
        let dayKey = dateFormatter.string(from: streakDate)
        guard let entry = calendar.entries[dayKey],
              isEntrySuccess(entry: entry, calendar: calendar)
        else {
            break
        }

        currentStreak += 1
        streakDate = dayCalendar.date(byAdding: .day, value: -1, to: streakDate) ?? streakDate
    }

    // Yesterday success.
    let yesterday = dayCalendar.date(byAdding: .day, value: -1, to: today) ?? today
    let yesterdayKey = dateFormatter.string(from: yesterday)
    let completedYesterday = calendar.entries[yesterdayKey].map {
        isEntrySuccess(entry: $0, calendar: calendar)
    } ?? false

    // Weekly completion over last 7 days.
    var weeklyDate = today
    for _ in 0 ..< 7 {
        let dayKey = dateFormatter.string(from: weeklyDate)
        if let entry = calendar.entries[dayKey],
           isEntrySuccess(entry: entry, calendar: calendar)
        {
            weeklyCompleted += 1
        }
        weeklyDate = dayCalendar.date(byAdding: .day, value: -1, to: weeklyDate) ?? weeklyDate
    }

    let weeklyCompletionRate = Double(weeklyCompleted) / 7.0

    return StreakStats(
        currentStreak: currentStreak,
        completedYesterday: completedYesterday,
        weeklyCompletionRate: weeklyCompletionRate
    )
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

/// Streak statistics for notification content
private struct StreakStats {
    let currentStreak: Int
    let completedYesterday: Bool
    let weeklyCompletionRate: Double
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

    let notificationId = "\(resolvedCalendar.id.uuidString)\(streakProtectionIdentifierSuffix)"
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
                            store: store,
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
    }
}

/// Schedule all reminder times for a calendar
private func _scheduleAllReminders(
    for calendar: CustomCalendar,
    reminderTimes: [(hour: Int, minute: Int, isPrimary: Bool)],
    store: CustomCalendarStore?,
    completion: @escaping (Result<Void, NotificationError>) -> Void
) {
    let group = DispatchGroup()
    var errors: [Error] = []

    var additionalIndex = 0
    for reminderTime in reminderTimes {
        group.enter()

        let notificationId: String
        if reminderTime.isPrimary {
            notificationId = calendar.id.uuidString
        } else {
            notificationId = "\(calendar.id.uuidString)-\(additionalIndex)"
            additionalIndex += 1
        }

        _scheduleNotificationInternal(
            for: calendar,
            notificationId: notificationId,
            hour: reminderTime.hour,
            minute: reminderTime.minute,
            store: store
        ) { result in
            if case let .failure(error) = result {
                errors.append(error)
            }
            group.leave()
        }
    }

    group.notify(queue: .main) {
        if let firstError = errors.first as? NotificationError {
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
    store: CustomCalendarStore?,
    completion: @escaping (Result<Void, NotificationError>) -> Void
) {
    let content = UNMutableNotificationContent()

    // Apply privacy mode settings with dynamic content
    switch calendar.notificationPrivacyMode {
    case .full:
        // Use dynamic, motivational content if store is available
        if let store = store {
            let dynamicContent = generateDynamicContent(for: calendar, store: store)
            content.title = dynamicContent.title
            content.body = dynamicContent.body
        } else {
            // Fallback to static content
            let titleFormat = NSLocalizedString(
                "notification.reminder.title.full",
                value: "Time to log %@",
                comment: "Notification title with habit name"
            )
            content.title = String(format: titleFormat, calendar.name)

            let bodyFormat = NSLocalizedString(
                "notification.reminder.body.full",
                value: "Don't forget to track %@ today! (Target: %d)",
                comment: "Notification body with habit name and target"
            )
            content.body = String(format: bodyFormat, calendar.name, calendar.dailyTarget)
        }

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
        "calendarName": calendar.name,
    ]

    // Set up timezone-aware trigger
    var components = DateComponents()
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
