import SharedModels
import SwiftUI

extension TrackingType {
  var displayName: String {
    switch self {
    case .binary:
      String(localized: "Binary")
    case .counter:
      String(localized: "Counter")
    case .multipleDaily:
      String(localized: "Target")
    }
  }

  var displayTitle: LocalizedStringKey {
    switch self {
    case .binary:
      "Binary"
    case .counter:
      "Counter"
    case .multipleDaily:
      "Target"
    }
  }

  func detailDescription(for cadence: CalendarCadence) -> LocalizedStringKey {
    switch self {
    case .binary:
      return cadence == .daily
        ? "Track a simple yes/no each day. Great for habits you either complete or skip."
        : "Track a simple yes/no each week. Great for goals you either hit or miss across the week."
    case .counter:
      return cadence == .daily
        ? "Log a numeric value per day, like pages read or minutes practiced."
        : "Log a numeric value per week, like workouts done or kilometers covered."
    case .multipleDaily:
      return cadence == .daily
        ? "Check in multiple times per day toward a daily target."
        : "Check in multiple times across the week toward a weekly target."
    }
  }
}
