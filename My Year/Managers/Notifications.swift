import SharedModels
import UserNotifications

// MARK: - Notification Action Identifiers

public enum NotificationAction {
    public static let quickLog = "QUICK_LOG_ACTION"
    public static let snooze = "SNOOZE_ACTION"
    public static let categoryIdentifier = "HABIT_REMINDER"
}

private struct NotificationPlan {
    let id: String
    let content: UNNotificationContent
    let trigger: UNNotificationTrigger
}

private enum NotificationRequestID {
    private static let streakProtectionSuffix = "-streak-protection"

    static func primary(calendarId: UUID) -> String {
        "\(calendarId.uuidString)-primary"
    }

    static func additional(calendarId: UUID, index: Int) -> String {
        "\(calendarId.uuidString)-additional-\(index)"
    }

    static func streakProtection(calendarId: UUID) -> String {
        "\(calendarId.uuidString)\(streakProtectionSuffix)"
    }

    static func snooze(calendarId: UUID) -> String {
        "\(calendarId.uuidString)-snooze"
    }

    static func isStreakProtection(_ id: String) -> Bool {
        id.hasSuffix(streakProtectionSuffix)
    }

    static func calendarId(notificationIdentifier: String, userInfoCalendarId: String?) -> UUID? {
        if let userInfoCalendarId,
           let calendarId = UUID(uuidString: userInfoCalendarId)
        {
            return calendarId
        }

        if let calendarId = UUID(uuidString: notificationIdentifier) {
            return calendarId
        }

        guard notificationIdentifier.count >= 36 else {
            return nil
        }
        return UUID(uuidString: String(notificationIdentifier.prefix(36)))
    }
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
        case let .schedulingFailed(error):
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

// MARK: - Reminder Content

private func makeReminderContent(
    for calendar: CustomCalendar,
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
        let bodyFormat = fullReminderBodyFormat(isPrimary: isPrimary)
        return (title, String(format: bodyFormat, calendar.name))

    case .generic:
        let title = NSLocalizedString(
            "notification.reminder.title.generic",
            value: "Habit Reminder",
            comment: "Generic notification title"
        )
        return (title, genericReminderBody(isPrimary: isPrimary))

    case .hidden:
        return ("", "")
    }
}

private func fullReminderBodyFormat(isPrimary: Bool) -> String {
    if isPrimary {
        return NSLocalizedString(
            "notification.reminder.primary.full",
            value: "Time for today's check-in. Log %@.",
            comment: "Daily primary reminder body with habit name"
        )
    }

    return NSLocalizedString(
        "notification.reminder.additional.full",
        value: "Quick check-in: log %@.",
        comment: "Additional reminder body with habit name"
    )
}

private func genericReminderBody(isPrimary: Bool) -> String {
    if isPrimary {
        return NSLocalizedString(
            "notification.reminder.primary.generic",
            value: "Time for today's check-in. Log your habit.",
            comment: "Daily primary generic reminder body"
        )
    }

    return NSLocalizedString(
        "notification.reminder.additional.generic",
        value: "Quick check-in. Log your habit.",
        comment: "Additional generic reminder body"
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

// MARK: - Request ID Utilities

/// Best-effort derivation of the calendar id a notification request belongs to.
/// We prefer `userInfo["calendarId"]` since request identifiers may include suffixes
/// (e.g. `-0`, `-streak-protection`, `-snooze`).
func deriveCalendarId(notificationIdentifier: String, userInfoCalendarId: String?) -> UUID? {
    NotificationRequestID.calendarId(
        notificationIdentifier: notificationIdentifier,
        userInfoCalendarId: userInfoCalendarId
    )
}

private func deriveCalendarId(from request: UNNotificationRequest) -> UUID? {
    deriveCalendarId(
        notificationIdentifier: request.identifier,
        userInfoCalendarId: request.content.userInfo["calendarId"] as? String
    )
}

private func removePendingNotifications(for calendarId: UUID) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
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

            continuation.resume()
        }
    }
}

private func removeAllPendingStreakProtectionNotifications() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request -> String? in
                NotificationRequestID.isStreakProtection(request.identifier) ? request.identifier : nil
            }

            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }

            continuation.resume()
        }
    }
}

// MARK: - Streak Protection

/// Schedules a streak protection reminder for late in the day
/// - Parameters:
///   - calendar: The calendar to protect
///   - store: Calendar store for streak calculation
private func scheduleStreakProtectionReminder(
    for calendar: CustomCalendar,
    store: CustomCalendarStore
) {
    Task {
        let notificationId = NotificationRequestID.streakProtection(calendarId: calendar.id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])

        guard let plan = makeStreakProtectionPlan(for: calendar, store: store) else {
            return
        }

        do {
            try await scheduleNotificationPlans([plan])
        } catch {
            print("❌ Failed to schedule streak protection notification: \(error)")
        }
    }
}

private func makeStreakProtectionPlan(for calendar: CustomCalendar, store: CustomCalendarStore) -> NotificationPlan? {
    guard calendar.streakProtectionEnabled,
          calendar.recurringReminderEnabled
    else { return nil }

    if let todayEntry = store.getEntry(calendarId: calendar.id, date: Date()),
       isEntryFulfilledForNotification(todayEntry, calendar: calendar)
    {
        return nil
    }

    let streakAtRisk = calculateStreakEndingYesterday(for: calendar)

    guard streakAtRisk >= calendar.streakProtectionThreshold else { return nil }

    let now = Date()
    let calendarSwift = Calendar.current
    guard let ninePM = calendarSwift.date(bySettingHour: 21, minute: 0, second: 0, of: now),
          ninePM > now
    else { return nil }

    let triggerDate = calendarSwift.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: ninePM
    )

    return NotificationPlan(
        id: NotificationRequestID.streakProtection(calendarId: calendar.id),
        content: makeStreakProtectionContent(for: calendar, streakAtRisk: streakAtRisk),
        trigger: UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    )
}

private func makeStreakProtectionContent(for calendar: CustomCalendar, streakAtRisk: Int) -> UNNotificationContent {
    let content = UNMutableNotificationContent()

    switch calendar.notificationPrivacyMode {
    case .full:
        content.title = String(
            format: String(localized: "🔥 Don't break your %lld-day streak!"),
            streakAtRisk
        )
        content.body = String(
            format: String(localized: "Quick! Log %@ before midnight"),
            calendar.name
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
        "calendarId": calendar.id.uuidString,
        "calendarName": calendar.name,
        "isStreakProtection": true,
    ]

    return content
}

/// Refreshes one-time streak protection reminders for all calendars.
/// Call on app launch / app active to re-evaluate daily streak risk.
public func refreshStreakProtectionReminders(store: CustomCalendarStore) {
    Task {
        await removeAllPendingStreakProtectionNotifications()

        await MainActor.run {
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

/// Replaces every pending notification for a calendar with the current reminder plan.
/// - Parameters:
///   - calendar: The calendar to reschedule notifications for
///   - store: Calendar store for streak-protection checks
///   - completion: Completion handler called with result (success or error)
public func rescheduleNotifications(
    for calendar: CustomCalendar,
    store: CustomCalendarStore
) async throws {
    await removePendingNotifications(for: calendar.id)

    guard !calendar.isArchived,
          calendar.recurringReminderEnabled
    else {
        return
    }

    let reminderPlans = makeReminderPlans(for: calendar)
    guard !reminderPlans.isEmpty else {
        return
    }

    try await requestNotificationAuthorizationIfNeeded()
    let plans = reminderPlans + [makeStreakProtectionPlan(for: calendar, store: store)].compactMap { $0 }
    try await scheduleNotificationPlans(plans)
}

private func makeReminderPlans(for calendar: CustomCalendar) -> [NotificationPlan] {
    var plans: [NotificationPlan] = []

    if let hour = calendar.reminderHour,
       let minute = calendar.reminderMinute
    {
        plans.append(
            makeReminderPlan(
                for: calendar,
                id: NotificationRequestID.primary(calendarId: calendar.id),
                hour: hour,
                minute: minute,
                isPrimary: true
            )
        )
    }

    for (index, reminderTime) in calendar.additionalReminderTimes.enumerated() {
        plans.append(
            makeReminderPlan(
                for: calendar,
                id: NotificationRequestID.additional(calendarId: calendar.id, index: index),
                hour: reminderTime.hour,
                minute: reminderTime.minute,
                isPrimary: false
            )
        )
    }

    return plans
}

private func makeReminderPlan(
    for calendar: CustomCalendar,
    id: String,
    hour: Int,
    minute: Int,
    isPrimary: Bool
) -> NotificationPlan {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute

    if let timeZoneIdentifier = calendar.reminderTimeZone,
       let timeZone = TimeZone(identifier: timeZoneIdentifier)
    {
        components.timeZone = timeZone
    } else {
        components.timeZone = TimeZone.current
    }

    return NotificationPlan(
        id: id,
        content: makeReminderNotificationContent(for: calendar, isPrimary: isPrimary),
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    )
}

private func makeReminderNotificationContent(
    for calendar: CustomCalendar,
    isPrimary: Bool
) -> UNNotificationContent {
    let content = UNMutableNotificationContent()
    let reminderContent = makeReminderContent(for: calendar, isPrimary: isPrimary)

    content.title = reminderContent.title
    content.body = reminderContent.body
    if calendar.notificationPrivacyMode == .hidden {
        content.badge = NSNumber(value: 1)
    }

    content.sound = .default
    content.categoryIdentifier = NotificationAction.categoryIdentifier
    content.userInfo = [
        "calendarId": calendar.id.uuidString,
        "calendarName": calendar.name,
    ]

    return content
}

private func requestNotificationAuthorizationIfNeeded() async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, error in
                    if let error {
                        continuation.resume(throwing: NotificationError.schedulingFailed(error))
                    } else if granted {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: NotificationError.permissionDenied)
                    }
                }

            case .authorized, .provisional:
                continuation.resume()

            case .denied:
                continuation.resume(throwing: NotificationError.permissionDenied)

            case .ephemeral:
                continuation.resume(throwing: NotificationError.unsupportedMode)

            @unknown default:
                continuation.resume(throwing: NotificationError.unknownStatus)
            }
        }
    }
}

private func scheduleNotificationPlans(_ plans: [NotificationPlan]) async throws {
    guard !plans.isEmpty else {
        return
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        let group = DispatchGroup()
        let errorsQueue = DispatchQueue(label: "notification-scheduling-errors")
        var errors: [NotificationError] = []

        for plan in plans {
            group.enter()
            let request = UNNotificationRequest(
                identifier: plan.id,
                content: plan.content,
                trigger: plan.trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    errorsQueue.sync {
                        errors.append(.schedulingFailed(error))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let firstError = errorsQueue.sync { errors.first }
            if let firstError {
                continuation.resume(throwing: firstError)
            } else {
                continuation.resume()
            }
        }
    }
}

// MARK: - Notification Cancellation

/// Cancels all pending notifications for a calendar
/// - Parameter calendar: The calendar whose notifications should be cancelled
public func cancelNotifications(for calendar: CustomCalendar) {
    Task {
        await removePendingNotifications(for: calendar.id)
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
    let notificationId = NotificationRequestID.snooze(calendarId: calendar.id)
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

    let plan = NotificationPlan(
        id: notificationId,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
    )

    Task {
        do {
            try await scheduleNotificationPlans([plan])
            print("⏰ Snoozed notification for \(calendar.name) for 1 hour")
        } catch {
            print("❌ Failed to schedule snooze notification: \(error)")
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
