import Foundation
import SharedModels

enum OnboardingHabitCatalog {
  static func habits(for commitment: IdentityCommitment) -> [String] {
    switch commitment {
    case .reader:
      [String(localized: "Read 1 page"), String(localized: "Read for 5 minutes"), String(localized: "Open a book")]
    case .strengthTrainer:
      [String(localized: "Move for 5 minutes"), String(localized: "Stretch for 5 minutes"), String(localized: "Do 1 bodyweight set")]
    case .writer:
      [String(localized: "Write 3 lines"), String(localized: "Write for 5 minutes"), String(localized: "Open a notebook")]
    case .meditator:
      [String(localized: "Meditate for 2 minutes"), String(localized: "Take 5 deep breaths"), String(localized: "Sit quietly for 2 minutes")]
    case .learner:
      [String(localized: "Learn for 5 minutes"), String(localized: "Watch 1 short lesson"), String(localized: "Write 1 thing you learned")]
    case .saver:
      [String(localized: "Set aside $5"), String(localized: "Check spending for 2 minutes"), String(localized: "Review 1 expense")]
    case .creator:
      [String(localized: "Create for 5 minutes"), String(localized: "Write 1 idea"), String(localized: "Open your project")]
    case .earlyBird:
      [String(localized: "Wake up 10 minutes earlier"), String(localized: "Get out of bed right away"), String(localized: "Drink 1 glass of water")]
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
