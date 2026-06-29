import Foundation

public enum CalendarSource: String, Codable, CaseIterable, Sendable {
    case manual
    case appleHealthSteps
    case appleHealthActiveEnergy
    case appleHealthExerciseMinutes
    case appleHealthWalkingRunningDistance
    case appleHealthFlightsClimbed
}

public enum AppleHealthMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case steps
    case activeEnergy
    case exerciseMinutes
    case walkingRunningDistance
    case flightsClimbed

    public var id: String { rawValue }

    public var source: CalendarSource {
        switch self {
        case .steps: return .appleHealthSteps
        case .activeEnergy: return .appleHealthActiveEnergy
        case .exerciseMinutes: return .appleHealthExerciseMinutes
        case .walkingRunningDistance: return .appleHealthWalkingRunningDistance
        case .flightsClimbed: return .appleHealthFlightsClimbed
        }
    }

    public init?(source: CalendarSource) {
        switch source {
        case .manual:
            return nil
        case .appleHealthSteps:
            self = .steps
        case .appleHealthActiveEnergy:
            self = .activeEnergy
        case .appleHealthExerciseMinutes:
            self = .exerciseMinutes
        case .appleHealthWalkingRunningDistance:
            self = .walkingRunningDistance
        case .appleHealthFlightsClimbed:
            self = .flightsClimbed
        }
    }

    public var title: String {
        switch self {
        case .steps: return String(localized: "Apple Health Steps")
        case .activeEnergy: return String(localized: "Apple Health Active Energy")
        case .exerciseMinutes: return String(localized: "Apple Health Exercise Minutes")
        case .walkingRunningDistance: return String(localized: "Apple Health Walking + Running Distance")
        case .flightsClimbed: return String(localized: "Apple Health Flights Climbed")
        }
    }

    public var defaultCalendarName: String {
        switch self {
        case .steps: return String(localized: "Daily Steps")
        case .activeEnergy: return String(localized: "Active Energy")
        case .exerciseMinutes: return String(localized: "Exercise Minutes")
        case .walkingRunningDistance: return String(localized: "Walking + Running")
        case .flightsClimbed: return String(localized: "Flights Climbed")
        }
    }

    public var description: String {
        switch self {
        case .steps:
            return String(localized: "Import daily step counts and complete Periods when you reach your target.")
        case .activeEnergy:
            return String(localized: "Import active calories from Apple Health and complete Periods at your target.")
        case .exerciseMinutes:
            return String(localized: "Import exercise minutes from Apple Health and complete Periods at your target.")
        case .walkingRunningDistance:
            return String(localized: "Import walking and running distance from Apple Health and complete Periods at your target.")
        case .flightsClimbed:
            return String(localized: "Import flights climbed from Apple Health and complete Periods at your target.")
        }
    }

    public var targetLabel: String {
        switch self {
        case .steps: return String(localized: "Steps per day")
        case .activeEnergy: return String(localized: "Active calories per day")
        case .exerciseMinutes: return String(localized: "Exercise minutes per day")
        case .walkingRunningDistance: return String(localized: "Meters per day")
        case .flightsClimbed: return String(localized: "Flights per day")
        }
    }

    public var defaultTarget: Int {
        switch self {
        case .steps: return 8_000
        case .activeEnergy: return 300
        case .exerciseMinutes: return 30
        case .walkingRunningDistance: return 5_000
        case .flightsClimbed: return 10
        }
    }

    public var unit: UnitOfMeasure {
        switch self {
        case .steps: return .steps
        case .activeEnergy: return .calories
        case .exerciseMinutes: return .minutes
        case .walkingRunningDistance: return .meters
        case .flightsClimbed: return .floors
        }
    }

    public var defaultColor: String {
        switch self {
        case .steps: return "qs-amber"
        case .activeEnergy: return "qs-orange"
        case .exerciseMinutes: return "qs-green"
        case .walkingRunningDistance: return "qs-blue"
        case .flightsClimbed: return "qs-purple"
        }
    }
}
