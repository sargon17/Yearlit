import Foundation
import SharedModels

enum OnboardingHabitCatalog {
  static func habits(for commitment: IdentityCommitment) -> [String] {
    switch commitment {
    case .reader:
      ["Read 1 page", "Read for 5 minutes", "Open a book"]
    case .strengthTrainer:
      ["Move for 5 minutes", "Stretch for 5 minutes", "Do 1 bodyweight set"]
    case .writer:
      ["Write 3 lines", "Write for 5 minutes", "Open a notebook"]
    case .meditator:
      ["Meditate for 2 minutes", "Take 5 deep breaths", "Sit quietly for 2 minutes"]
    case .learner:
      ["Learn for 5 minutes", "Watch 1 short lesson", "Write 1 thing you learned"]
    case .saver:
      ["Set aside $5", "Check spending for 2 minutes", "Review 1 expense"]
    case .creator:
      ["Create for 5 minutes", "Write 1 idea", "Open your project"]
    case .earlyBird:
      ["Wake up 10 minutes earlier", "Get out of bed right away", "Drink 1 glass of water"]
    }
  }
}

enum OnboardingFirstCalendarFactory {
  static func makeCalendar(title: String, today: Date) -> CustomCalendar {
    CustomCalendar(
      name: title,
      color: "qs-orange",
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
