import AppIntents
import Foundation

public struct ReminderTime: Codable, Hashable, Identifiable {
    public var id: String {
        "\(hour):\(minute)"
    }

    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public init(from date: Date) {
        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
    }

    public func toDate(referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        let safeHour = min(max(hour, 0), 23)
        let safeMinute = min(max(minute, 0), 59)
        return calendar.date(bySettingHour: safeHour, minute: safeMinute, second: 0, of: referenceDate)
            ?? referenceDate
    }
}

public enum NotificationPrivacyMode: String, Codable, CaseIterable {
    case full
    case generic
    case hidden

    public var description: String {
        switch self {
        case .full:
            return String(localized: "Full Details")
        case .generic:
            return String(localized: "Generic Message")
        case .hidden:
            return String(localized: "No Text (Badge Only)")
        }
    }

    public var detail: String {
        switch self {
        case .full:
            return String(localized: "Show habit name and target in notifications")
        case .generic:
            return String(localized: "Show generic reminder message")
        case .hidden:
            return String(localized: "Only badge and sound, no text visible on lock screen")
        }
    }
}

public enum CalendarCadence: String, Codable, CaseIterable {
    case daily
    case weekly

    public var title: String {
        switch self {
        case .daily:
            return String(localized: "Daily")
        case .weekly:
            return String(localized: "Weekly")
        }
    }

    public var targetTitle: String {
        switch self {
        case .daily:
            return String(localized: "Daily Target")
        case .weekly:
            return String(localized: "Weekly Target")
        }
    }

    public var periodTitle: String {
        switch self {
        case .daily:
            return String(localized: "day")
        case .weekly:
            return String(localized: "week")
        }
    }

    public var detailDescription: String {
        switch self {
        case .daily:
            return String(localized: "Track progress one day at a time.")
        case .weekly:
            return String(
                localized: "Track progress across each week, with one dot per week in the year view."
            )
        }
    }

    public var icon: String {
        switch self {
        case .daily:
            return "sun.max"
        case .weekly:
            return "calendar"
        }
    }
}

public enum TrackingType: String, Codable, CaseIterable {
    case binary
    case counter
    case multipleDaily

    public var description: String {
        switch self {
        case .binary:
            return String(localized: "Once a day")
        case .counter:
            return String(localized: "Multiple times (unlimited)")
        case .multipleDaily:
            return String(localized: "Multiple times (with target)")
        }
    }

    public var icon: String {
        switch self {
        case .binary: return "checkmark.circle"
        case .counter: return "chevron.up.forward.dotted.2"
        case .multipleDaily: return "target"
        }
    }

    public var label: String {
        switch self {
        case .binary: return "binary"
        case .counter: return "counter"
        case .multipleDaily: return "target"
        }
    }

    public var analyticsValue: String {
        switch self {
        case .binary:
            return "binary"
        case .counter:
            return "counter"
        case .multipleDaily:
            return "multiple_daily"
        }
    }

    public var detailDescription: String {
        switch self {
        case .binary:
            return String(
                localized: "Track a simple yes/no each day. Great for habits you either complete or skip."
            )
        case .counter:
            return String(localized: "Log a numeric value per day, like pages read or minutes practiced.")
        case .multipleDaily:
            return String(localized: "Check in multiple times per day toward a daily target.")
        }
    }

    @available(iOS 17.0, macOS 13.0, *)
    public static var allCasesDisplayRepresentations: [TrackingType: DisplayRepresentation] {
        [
            .binary: DisplayRepresentation(title: LocalizedStringResource("Once a day (binary)")),
            .counter: DisplayRepresentation(
                title: LocalizedStringResource("Multiple times (unlimited) (counter)")
            ),
            .multipleDaily: DisplayRepresentation(
                title: LocalizedStringResource("Multiple times (with target) (multipleDaily)")
            )
        ]
    }
}

public struct CalendarEntry: Codable {
    public let date: Date
    public var count: Int
    public var completed: Bool

    public init(date: Date, count: Int = 0, completed: Bool = false) {
        self.date = date
        self.count = count
        self.completed = completed
    }
}

public enum AppleHealthMetricEntryMapper {
    public static func entries(from valuesByDate: [Date: Int], target: Int) -> [String: CalendarEntry] {
        let resolvedTarget = max(1, target)
        return valuesByDate.reduce(into: [String: CalendarEntry]()) { entries, pair in
            let date = LocalDayCalendar.startOfDay(for: pair.key)
            let count = max(0, pair.value)
            guard count > 0 else { return }
            entries[DayKeyFormatter.shared.string(from: date)] = CalendarEntry(
                date: date,
                count: count,
                completed: count >= resolvedTarget
            )
        }
    }
}

public enum ValidationError: Error {
    case invalidHour(Int)
    case invalidMinute(Int)
}
