import Foundation
import SharedModels

enum OnboardingHabitCatalog {
    static func habits(for commitment: IdentityCommitment) -> [String] {
        switch commitment {
        case .runner:
            ["Run for 10 minutes", "Put on running shoes", "Walk one block"]
        case .reader:
            ["Read 2 pages", "Open a book after breakfast", "Read for 5 minutes"]
        case .learner:
            ["Watch one lesson", "Practice for 5 minutes", "Write one note"]
        case .meditator:
            ["Sit quietly for 2 minutes", "Take 3 deep breaths", "Meditate after waking"]
        case .strengthTrainer:
            ["Do 5 pushups", "Do one bodyweight set", "Lift for 5 minutes"]
        case .healthyEater:
            ["Add one vegetable", "Drink a glass of water", "Pack a simple snack"]
        }
    }
}

enum OnboardingFirstCalendarFactory {
    static func makeCalendar(title: String, today: Date) -> CustomCalendar {
        CustomCalendar(
            name: title,
            color: "qs-amber",
            cadence: .daily,
            trackingType: .binary,
            trackingStartedAt: LocalDayCalendar.startOfDay(for: today),
            dailyTarget: 1,
            entries: [:],
            isArchived: false,
            recurringReminderEnabled: false,
            reminderTime: nil,
            reminderWeekday: nil,
            unit: nil,
            defaultRecordValue: nil,
            currencySymbol: nil,
            reminderTimeZone: TimeZone.current.identifier,
            notificationPrivacyMode: .full,
            suppressWhenCompleted: true,
            additionalReminderTimes: [],
            streakProtectionEnabled: true,
            streakProtectionThreshold: 5
        )
    }
}
