import Foundation
import UserNotifications

enum RetentionNotificationStage: String, CaseIterable {
    case day3
    case day7
    case day21

    var identifier: String {
        "app.retention.\(rawValue)"
    }

    var offsetDays: Int {
        switch self {
        case .day3: return 3
        case .day7: return 7
        case .day21: return 21
        }
    }

    var title: String {
        switch self {
        case .day3:
            return String(localized: "Still building your year?")
        case .day7:
            return String(localized: "Pick up where you left off")
        case .day21:
            return String(localized: "Your year isn’t over")
        }
    }

    var body: String {
        switch self {
        case .day3:
            return String(localized: "A quick check-in can help you keep momentum.")
        case .day7:
            return String(localized: "One small step is enough to restart.")
        case .day21:
            return String(localized: "Come back when you’re ready. Today works.")
        }
    }

    var userInfo: [String: String] {
        [
            "notificationScope": "app",
            "notificationKind": "retention",
            "retentionStage": rawValue
        ]
    }
}

func retentionFireDate(
    for stage: RetentionNotificationStage,
    baseDate: Date,
    calendar: Calendar = Calendar.current
) -> Date? {
    let baseDay = calendar.startOfDay(for: baseDate)
    guard let targetDay = calendar.date(byAdding: .day, value: stage.offsetDays, to: baseDay) else {
        return nil
    }

    return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDay)
}

func retentionLocalDayKey(for date: Date, calendar: Calendar = Calendar.current) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    guard let year = components.year, let month = components.month, let day = components.day else {
        assertionFailure("Missing local day components")
        return ""
    }

    return String(format: "%04d-%02d-%02d", year, month, day)
}

func cancelPendingRetentionNotifications() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: RetentionNotificationStage.allCases.map(\.identifier)
    )
}

func refreshRetentionNotificationsIfNeeded(
    onboardingSeen: Bool,
    now: Date = Date(),
    userDefaults: UserDefaults = .standard
) async {
    guard shouldContinueRetentionRefresh(onboardingSeen: onboardingSeen) else { return }

    let settings = await UNUserNotificationCenter.current().notificationSettings()
    guard !Task.isCancelled else { return }

    guard canScheduleRetentionNotifications(for: settings.authorizationStatus) else {
        guard !Task.isCancelled else { return }
        cancelPendingRetentionNotifications()
        return
    }

    let todayKey = retentionLocalDayKey(for: now)
    guard userDefaults.string(forKey: AppStorageKeys.retentionLastRescheduleLocalDay) != todayKey else {
        return
    }

    let requests = retentionNotificationRequests(baseDate: now)

    guard !Task.isCancelled else { return }
    cancelPendingRetentionNotifications()

    do {
        for request in requests {
            guard !Task.isCancelled else { return }
            try await UNUserNotificationCenter.current().add(request)
        }

        userDefaults.set(todayKey, forKey: AppStorageKeys.retentionLastRescheduleLocalDay)
    } catch {
        guard !Task.isCancelled else { return }
        cancelPendingRetentionNotifications()
        NSLog("Failed to schedule retention notifications: \(error)")
    }
}

private func shouldContinueRetentionRefresh(onboardingSeen: Bool) -> Bool {
    guard !Task.isCancelled else { return false }
    guard onboardingSeen else {
        cancelPendingRetentionNotifications()
        return false
    }
    return true
}

private func canScheduleRetentionNotifications(for status: UNAuthorizationStatus) -> Bool {
    status == .authorized || status == .provisional
}

private func retentionNotificationRequests(baseDate: Date) -> [UNNotificationRequest] {
    RetentionNotificationStage.allCases.compactMap { stage in
        retentionNotificationRequest(for: stage, baseDate: baseDate)
    }
}

private func retentionNotificationRequest(
    for stage: RetentionNotificationStage,
    baseDate: Date
) -> UNNotificationRequest? {
    guard let fireDate = retentionFireDate(for: stage, baseDate: baseDate) else {
        return nil
    }

    let content = UNMutableNotificationContent()
    content.title = stage.title
    content.body = stage.body
    content.sound = .default
    content.userInfo = stage.userInfo

    let triggerDate = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: fireDate
    )
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    return UNNotificationRequest(identifier: stage.identifier, content: content, trigger: trigger)
}
