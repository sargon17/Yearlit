import Foundation

public enum CalendarTimelineMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case your365
    case calendarYear

    public var id: String {
        rawValue
    }

    public var title: String {
        switch self {
        case .your365:
            return "Your 365"
        case .calendarYear:
            return "Calendar Year"
        }
    }

    public var detail: String {
        switch self {
        case .your365:
            return "Each habit starts its own 365-day journey from the day you began."
        case .calendarYear:
            return "View progress from January to December."
        }
    }

    public func effectiveMode(for cadence: CalendarCadence) -> CalendarTimelineMode {
        cadence == .weekly ? .calendarYear : self
    }
}

