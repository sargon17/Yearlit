import SharedModels
import SwiftUI

enum CalendarShareTemplate: String, CaseIterable, Identifiable {
    case yearCard
    case minimalGrid
    case streakFocus
    case performance
    case your365

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .yearCard:
            return String(localized: "Year Card")
        case .minimalGrid:
            return String(localized: "Minimal Grid")
        case .streakFocus:
            return String(localized: "Streak Focus")
        case .performance:
            return String(localized: "Performance")
        case .your365:
            return String(localized: "Your 365")
        }
    }

    var subtitle: String {
        switch self {
        case .yearCard:
            return String(localized: "Full-year grid + stats")
        case .minimalGrid:
            return String(localized: "Clean grid only")
        case .streakFocus:
            return String(localized: "Streaks + grid strip")
        case .performance:
            return String(localized: "Trends and progress")
        case .your365:
            return String(localized: "Personal habit-year card")
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .performance:
            return true
        case .yearCard, .minimalGrid, .streakFocus, .your365:
            return false
        }
    }
}

func availableShareTemplates(for calendar: CustomCalendar, today: Date) -> [CalendarShareTemplate] {
    let your365Snapshot = calendar.cadence == .daily
        ? calendar.makeYour365Snapshot(
            completedDates: your365CompletedDates(for: calendar),
            today: today
        )
        : nil

    return CalendarShareTemplate.allCases.filter { template in
        switch template {
        case .your365:
            return your365Snapshot != nil
        case .yearCard, .minimalGrid, .streakFocus, .performance:
            return true
        }
    }
}
