import Foundation
@preconcurrency import SharedModels
import UserNotifications

private let streakProtectionIdentifierSuffix = "-streak-protection"

private func previousCadenceDate(for calendar: CustomCalendar, relativeTo date: Date) -> Date {
    let localCalendar = LocalDayCalendar.calendar
    switch calendar.cadence {
    case .daily:
        return localCalendar.date(byAdding: .day, value: -1, to: date) ?? date
    case .weekly:
        let currentWeek = LocalDayCalendar.startOfWeek(for: date)
        return localCalendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
    }
}

private func streakProtectionReferenceDate(for calendar: CustomCalendar, now: Date) -> Date {
    switch calendar.cadence {
    case .daily:
        return now
    case .weekly:
        let localCalendar = LocalDayCalendar.calendar
        let weekStart = LocalDayCalendar.startOfWeek(for: now)
        return localCalendar.date(byAdding: .day, value: 6, to: weekStart)
            ?? LocalDayCalendar.startOfDay(for: now)
    }
}

private func removeAllPendingStreakProtectionNotifications(completion: @escaping () -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        let identifiersToRemove = requests.compactMap { request -> String? in
            request.identifier.hasSuffix(streakProtectionIdentifierSuffix) ? request.identifier : nil
        }

        if !identifiersToRemove.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: identifiersToRemove
            )
        }

        completion()
    }
}

// MARK: - Streak Protection

/// Schedules a streak protection reminder for late in the day.
@MainActor
public func scheduleStreakProtectionReminder(
    for calendar: CustomCalendar,
    store: CustomCalendarStore
) {
    guard calendar.streakProtectionEnabled,
          calendar.recurringReminderEnabled
    else {
        return
    }

    let now = Date()
    let protectionDate = streakProtectionReferenceDate(for: calendar, now: now)

    if let todayEntry = store.getEntry(calendarId: calendar.id, date: protectionDate),
       isEntryFulfilledForNotification(todayEntry, calendar: calendar) {
        return
    }

    let streakAtRisk = calculateStreakEndingPreviousPeriod(for: calendar, now: now)
    guard streakAtRisk >= calendar.streakProtectionThreshold else {
        return
    }

    let calendarSystem = Calendar.current
    guard let ninePM = calendarSystem.date(bySettingHour: 21, minute: 0, second: 0, of: protectionDate),
          ninePM > now
    else {
        return
    }

    let content = streakProtectionContent(for: calendar, streakAtRisk: streakAtRisk)
    let triggerDate = calendarSystem.dateComponents([.year, .month, .day, .hour, .minute], from: ninePM)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    let notificationId = "\(calendar.id.uuidString)\(streakProtectionIdentifierSuffix)"
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            NSLog("Failed to schedule streak protection: \(error)")
        }
    }
}

private func streakProtectionContent(
    for calendar: CustomCalendar,
    streakAtRisk: Int
) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()

    switch calendar.notificationPrivacyMode {
    case .full:
        let streakUnit = calendar.cadence == .weekly ? "week" : "day"
        content.title = String(
            format: String(localized: "🔥 Don't break your %lld-%@ streak!"),
            streakAtRisk,
            streakUnit
        )
        content.body = calendar.cadence == .weekly
            ? String(format: String(localized: "Last chance to complete %@ this week"), calendar.name)
            : String(format: String(localized: "Quick! Log %@ before midnight"), calendar.name)

    case .generic:
        content.title = String(localized: "🔥 Streak at risk!")
        content.body = calendar.cadence == .weekly
            ? String(localized: "Don't forget to log your habit this week")
            : String(localized: "Don't forget to log your habit today")

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
        "isStreakProtection": true
    ]

    return content
}

/// Refreshes one-time streak protection reminders for all calendars.
/// Call on app launch / app active to re-evaluate daily streak risk.
public func refreshStreakProtectionReminders(store: CustomCalendarStore) {
    removeAllPendingStreakProtectionNotifications {
        Task { @MainActor in
            let calendars = store.snapshot.calendars
            for calendar in calendars where !calendar.isArchived {
                scheduleStreakProtectionReminder(for: calendar, store: store)
            }
        }
    }
}

/// Calculates consecutive fulfilled periods ending at the previous period.
private func calculateStreakEndingPreviousPeriod(for calendar: CustomCalendar, now: Date) -> Int {
    let dayCalendar = LocalDayCalendar.calendar
    let previousDate = previousCadenceDate(for: calendar, relativeTo: LocalDayCalendar.startOfDay(for: now))

    return WidgetStreak.currentStreak(
        calendar: calendar,
        today: previousDate,
        calendarSystem: dayCalendar,
        allowTodayMissing: false
    ).streak
}
