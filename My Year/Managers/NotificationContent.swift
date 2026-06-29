import Foundation
@preconcurrency import SharedModels
import UserNotifications

func makeReminderNotificationContent(
    for calendar: CustomCalendar,
    dynamicContentEnabled: Bool
) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()

    switch calendar.notificationPrivacyMode {
    case .full:
        let reminderContent = dynamicContentEnabled
            ? generateDynamicContent(for: calendar)
            : staticFullContent(for: calendar)
        content.title = reminderContent.title
        content.body = reminderContent.body
    case .generic:
        content.title = NSLocalizedString(
            "notification.reminder.title.generic",
            value: "Habit Reminder",
            comment: "Generic notification title"
        )
        content.body = calendar.cadence == .weekly
            ? String(localized: "Time to log your habit this week")
            : NSLocalizedString(
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
        "calendarName": calendar.name
    ]
    return content
}

/// Generates dynamic, motivational notification content based on calendar progress.
func generateDynamicContent(for calendar: CustomCalendar) -> (title: String, body: String) {
    let stats = calculateStreakStats(for: calendar)

    return (
        title: fullReminderTitle(for: calendar),
        body: dynamicReminderBody(for: calendar, stats: stats)
    )
}

private func staticFullContent(for calendar: CustomCalendar) -> (title: String, body: String) {
    let bodyFormat = NSLocalizedString(
        "notification.reminder.body.full",
        value: "Don't forget to track %@ today! (Target: %d)",
        comment: "Notification body with habit name and target"
    )
    let weeklyBodyFormat = String(localized: "Don't forget to track %@ this week! (Target: %d)")

    return (
        title: fullReminderTitle(for: calendar),
        body: calendar.cadence == .weekly
            ? String(format: weeklyBodyFormat, calendar.name, calendar.dailyTarget)
            : String(format: bodyFormat, calendar.name, calendar.dailyTarget)
    )
}

private func fullReminderTitle(for calendar: CustomCalendar) -> String {
    let titleFormat = NSLocalizedString(
        "notification.reminder.title.full",
        value: "Time to log %@",
        comment: "Notification title with habit name"
    )
    return String(format: titleFormat, calendar.name)
}

private func dynamicReminderBody(for calendar: CustomCalendar, stats: StreakStats) -> String {
    if stats.currentStreak >= 7 {
        return longStreakMessages(for: calendar, currentStreak: stats.currentStreak).randomValue
    } else if stats.currentStreak >= 3 {
        return growingStreakMessages(for: calendar, currentStreak: stats.currentStreak).randomValue
    } else if stats.completedPreviousPeriod {
        return previousPeriodMessages(for: calendar).randomValue
    } else if stats.currentPeriodProgress > 0.7 {
        return progressMessage(for: calendar, progress: stats.currentPeriodProgress)
    }

    return starterMessages(for: calendar).randomValue
}

private func longStreakMessages(for calendar: CustomCalendar, currentStreak: Int) -> [String] {
    let cadencePeriod = calendar.cadence == .weekly ? "week" : "day"
    let currentPeriodLabel = calendar.cadence == .weekly ? "this week" : "today"
    return [
        String(
            format: String(localized: "🔥 You're on a %lld-%@ streak! Keep it alive!"),
            currentStreak,
            cadencePeriod
        ),
        String(
            format: String(localized: "💪 %lld %@ strong! Don't break it now!"),
            currentStreak,
            cadencePeriod
        ),
        String(
            format: String(localized: "✨ Amazing! %lld %@ in a row. One more %@!"),
            currentStreak,
            cadencePeriod,
            currentPeriodLabel
        )
    ]
}

private func growingStreakMessages(for calendar: CustomCalendar, currentStreak: Int) -> [String] {
    let cadencePeriod = calendar.cadence == .weekly ? "week" : "day"
    let capitalizedCadencePeriod = String(cadencePeriod.prefix(1)).uppercased()
        + String(cadencePeriod.dropFirst())
    return [
        String(
            format: String(localized: "%lld %@ down! You're building momentum 🚀"),
            currentStreak,
            cadencePeriod
        ),
        String(
            format: String(localized: "%@ %lld of your streak! Keep going 💪"),
            capitalizedCadencePeriod,
            currentStreak
        ),
        String(
            format: String(localized: "Nice! %lld in a row. Let's make it %lld!"),
            currentStreak,
            currentStreak + 1
        )
    ]
}

private func previousPeriodMessages(for calendar: CustomCalendar) -> [String] {
    [
        calendar.cadence == .weekly
            ? String(localized: "Great job last week! Let's keep it going this week 🎯")
            : String(localized: "Great job yesterday! Let's keep it going today 🎯"),
        calendar.cadence == .weekly
            ? String(localized: "You did it last week, you can do it this week! 💚")
            : String(localized: "You did it yesterday, you can do it today! 💚"),
        calendar.cadence == .weekly
            ? String(localized: "Last week ✅ This week? Let's go! 🔥")
            : String(localized: "Yesterday ✅ Today? Let's go! 🔥")
    ]
}

private func progressMessage(for calendar: CustomCalendar, progress: Double) -> String {
    let progressPercent = progress.formatted(.percent.precision(.fractionLength(0)))
    return String(
        format: calendar.cadence == .weekly
            ? String(localized: "You're at %@ this week! Keep pushing 💪")
            : String(localized: "You're at %@ today! Keep pushing 💪"),
        progressPercent
    )
}

private func starterMessages(for calendar: CustomCalendar) -> [String] {
    [
        String(
            format: String(localized: "Time to build your habit! (Target: %lld)"),
            calendar.dailyTarget
        ),
        calendar.cadence == .weekly
            ? String(localized: "This week counts! Log your progress 📊")
            : String(localized: "Every day counts! Log your progress today 📊"),
        String(
            format: String(localized: "Small steps, big results. Let's track %@! 🎯"),
            calendar.name
        )
    ]
}

private func calculateStreakStats(
    for calendar: CustomCalendar
) -> StreakStats {
    let dayCalendar = LocalDayCalendar.calendar
    let today = LocalDayCalendar.startOfDay(for: Date())
    let currentStreak = WidgetStreak.currentStreak(
        calendar: calendar,
        today: today,
        calendarSystem: dayCalendar
    ).streak
    let previousDate = previousCadenceDate(for: calendar, relativeTo: today)
    let completedPreviousPeriod = calendar.entry(for: previousDate).map {
        isEntryFulfilledForNotification($0, calendar: calendar)
    } ?? false
    let currentPeriodProgress = normalizedProgress(for: calendar, entry: calendar.entry(for: today))

    return StreakStats(
        currentStreak: currentStreak,
        completedPreviousPeriod: completedPreviousPeriod,
        currentPeriodProgress: currentPeriodProgress
    )
}

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

private struct StreakStats {
    let currentStreak: Int
    let completedPreviousPeriod: Bool
    let currentPeriodProgress: Double
}

private extension Array where Element == String {
    var randomValue: String {
        randomElement() ?? ""
    }
}
