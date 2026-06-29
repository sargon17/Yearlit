import Foundation

public enum DayMood: String, Codable {
    case terrible = "😫"
    case bad = "😞"
    case neutral = "😐"
    case good = "😊"
    case excellent = "🤩"

    public var color: String {
        switch self {
        case .terrible: return "mood-terrible"
        case .bad: return "mood-bad"
        case .neutral: return "mood-neutral"
        case .good: return "mood-good"
        case .excellent: return "mood-excellent"
        }
    }
}

public enum DayMoodType: Hashable {
    case mood(DayMood) // Wraps the existing DayMood cases
    case notEvaluated // For days that could be evaluated but weren't
    case future // For future days

    /// Helper to convert DayMood to this type
    static func from(_ mood: DayMood) -> DayMoodType {
        return .mood(mood)
    }

    var color: String {
        switch self {
        case let .mood(mood):
            return mood.color
        case .notEvaluated:
            return "dot-active"
        case .future:
            return "dot-inactive"
        }
    }

    /// Add sorting priority
    var sortOrder: Int {
        switch self {
        case let .mood(mood):
            switch mood {
            case .terrible: return 0
            case .bad: return 1
            case .neutral: return 2
            case .good: return 3
            case .excellent: return 4
            }
        case .notEvaluated: return 5
        case .future: return 6
        }
    }
}

public struct DayValuation: Codable, Identifiable, Equatable {
    public let id: String // Format: "YYYY-MM-DD"
    public let mood: DayMood
    public let timestamp: Date
    public let note: String?

    public init(date: Date = Date(), mood: DayMood, note: String? = nil) {
        let canonicalDate = LocalDayCalendar.startOfDay(for: date)
        id = DayKeyFormatter.shared.string(from: canonicalDate)
        self.mood = mood
        timestamp = canonicalDate
        self.note = note
    }

    public static func == (lhs: DayValuation, rhs: DayValuation) -> Bool {
        return lhs.id == rhs.id && lhs.mood == rhs.mood && lhs.note == rhs.note
    }
}
