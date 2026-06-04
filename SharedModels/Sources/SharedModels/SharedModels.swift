import AppIntents
import Foundation
import Observation
import SwiftData
import SwiftUI
import WidgetKit

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - Unit of Measure Definition

public enum UnitOfMeasure: String, Codable, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case none = "None"

    /// Currency
    case currency = "Currency"

    // Quantity/Count
    case pages = "Pages"
    case items = "Items"
    case rounds = "Rounds"
    case servings = "Servings"
    case doses = "Doses"

    // Distance
    case meters = "m"
    case kilometers = "km"
    case miles = "Miles"
    case steps = "Steps"
    case floors = "Floors"

    // Volume
    case milliliters = "ml"
    case liters = "l"
    case ounces = "oz"
    case cups = "Cups"

    // Time
    case minutes = "Minutes"
    case hours = "Hours"

    // Weight
    case grams = "g"
    case kilograms = "kg"
    case pounds = "Pounds"

    // Energy/Calories
    case calories = "kcal"
    case kilojoules = "kJ"

    public enum Category: String, CaseIterable {
        case quantity = "Quantity/Count"
        case distance = "Distance"
        case volume = "Volume"
        case time = "Time"
        case weight = "Weight"
        case energy = "Energy/Calories"
        case currency = "Currency"
    }

    public var category: Category {
        switch self {
        case .pages, .items, .rounds, .servings, .doses, .none:
            return .quantity
        case .meters, .kilometers, .miles, .steps, .floors:
            return .distance
        case .milliliters, .liters, .ounces, .cups:
            return .volume
        case .minutes, .hours:
            return .time
        case .grams, .kilograms, .pounds:
            return .weight
        case .calories, .kilojoules:
            return .energy
        case .currency:
            return .currency
        }
    }

    /// Display name might be different from raw value for units like 'km'
    public var displayName: String {
        switch self {
        case .none: return String(localized: "Times")
        case .pages: return String(localized: "Pages")
        case .items: return String(localized: "Items")
        case .rounds: return String(localized: "Rounds")
        case .servings: return String(localized: "Servings")
        case .doses: return String(localized: "Doses")
        case .kilometers: return String(localized: "Kilometers (km)")
        case .meters: return String(localized: "Meters (m)")
        case .miles: return String(localized: "Miles")
        case .steps: return String(localized: "Steps")
        case .floors: return String(localized: "Floors")
        case .milliliters: return String(localized: "Milliliters (ml)")
        case .liters: return String(localized: "Liters (l)")
        case .ounces: return String(localized: "Ounces (oz)")
        case .cups: return String(localized: "Cups")
        case .minutes: return String(localized: "Minutes")
        case .hours: return String(localized: "Hours")
        case .grams: return String(localized: "Grams (g)")
        case .kilograms: return String(localized: "Kilograms (kg)")
        case .pounds: return String(localized: "Pounds")
        case .calories: return String(localized: "Calories (kcal)")
        case .kilojoules: return String(localized: "Kilojoules (kJ)")
        case .currency: return String(localized: "Currency")
        }
    }

    public static var allCasesGrouped: [Category: [UnitOfMeasure]] {
        Dictionary(grouping: allCases, by: { $0.category })
    }
}

public extension UnitOfMeasure.Category {
    var displayName: String {
        switch self {
        case .quantity: return String(localized: "Quantity/Count")
        case .distance: return String(localized: "Distance")
        case .volume: return String(localized: "Volume")
        case .time: return String(localized: "Time")
        case .weight: return String(localized: "Weight")
        case .energy: return String(localized: "Energy/Calories")
        case .currency: return String(localized: "Currency")
        }
    }
}

// MARK: - Custom Calendar Models

/// Represents a reminder time (hour and minute)
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

    /// Create from Date
    public init(from date: Date) {
        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
    }

    /// Convert to Date (today at this time)
    public func toDate() -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

public enum NotificationPrivacyMode: String, Codable, CaseIterable {
    case full // Show calendar name and target
    case generic // "Reminder: Log your habit"
    case hidden // Just badge/sound, no text

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
            return String(localized: "Track progress across each week, with one dot per week in the year view.")
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

public enum CalendarSource: String, Codable, CaseIterable {
    case manual
    case appleHealthSteps
}

public struct CustomCalendar: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var color: String // Store as hex or named color
    public var cadence: CalendarCadence
    public var trackingType: TrackingType
    public var trackingStartedAt: Date
    // Legacy persisted name kept to avoid risky data migration.
    // Semantically this is the target for the calendar cadence period
    // (daily for daily calendars, weekly for weekly calendars).
    public var dailyTarget: Int
    public var unit: UnitOfMeasure?
    public var currencySymbol: String?
    public var defaultRecordValue: Int?
    public var order: Int = 0
    public var isArchived: Bool
    public var recurringReminderEnabled: Bool
    public var reminderHour: Int?
    public var reminderMinute: Int?
    public var reminderWeekday: Int?
    public var reminderTimeZone: String? // Store TimeZone.identifier for proper timezone handling
    public var notificationPrivacyMode: NotificationPrivacyMode = .full // Privacy mode for notifications
    public var suppressWhenCompleted: Bool = true // Don't send notification if entry already completed
    public var additionalReminderTimes: [ReminderTime] = [] // Additional reminder times (beyond primary reminderHour/reminderMinute)
    public var streakProtectionEnabled: Bool = true // Send late-day reminder if streak at risk
    public var streakProtectionThreshold: Int = 5 // Minimum streak length to trigger protection (default: 5 days)
    public var source: CalendarSource
    public var entries: [String: CalendarEntry] // Date string -> Entry

    public init(
        id: UUID = UUID(), name: String, color: String, cadence: CalendarCadence = .daily,
        trackingType: TrackingType,
        trackingStartedAt: Date,
        dailyTarget: Int = 1, entries: [String: CalendarEntry] = [:],
        isArchived: Bool = false,
        recurringReminderEnabled: Bool = false, reminderTime: Date? = nil, order: Int = 0,
        reminderWeekday: Int? = nil,
        unit: UnitOfMeasure? = nil,
        defaultRecordValue: Int? = nil,
        currencySymbol: String? = nil,
        reminderTimeZone: String? = nil,
        notificationPrivacyMode: NotificationPrivacyMode = .full,
        suppressWhenCompleted: Bool = true,
        additionalReminderTimes: [ReminderTime] = [],
        streakProtectionEnabled: Bool = true,
        streakProtectionThreshold: Int = 5,
        source: CalendarSource = .manual
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.cadence = cadence
        self.trackingType = trackingType
        self.trackingStartedAt = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        self.dailyTarget = dailyTarget
        self.unit = unit
        self.defaultRecordValue = defaultRecordValue
        self.currencySymbol = currencySymbol
        self.isArchived = isArchived
        self.recurringReminderEnabled = recurringReminderEnabled
        self.order = order
        self.reminderWeekday = reminderWeekday
        self.reminderTimeZone = reminderTimeZone ?? TimeZone.current.identifier
        self.notificationPrivacyMode = notificationPrivacyMode
        self.suppressWhenCompleted = suppressWhenCompleted
        self.additionalReminderTimes = additionalReminderTimes
        self.streakProtectionEnabled = streakProtectionEnabled
        self.streakProtectionThreshold = streakProtectionThreshold
        self.source = source
        if let time = reminderTime {
            let calendar = Calendar.current
            reminderHour = calendar.component(.hour, from: time)
            reminderMinute = calendar.component(.minute, from: time)
        } else {
            reminderHour = nil
            reminderMinute = nil
        }
        self.entries = entries
    }

    /// New initializer using hour and minute directly
    public init(
        id: UUID = UUID(), name: String, color: String, cadence: CalendarCadence = .daily,
        trackingType: TrackingType,
        trackingStartedAt: Date,
        dailyTarget: Int = 1, entries: [String: CalendarEntry] = [:],
        isArchived: Bool = false,
        recurringReminderEnabled: Bool = false, reminderHour: Int? = nil, reminderMinute: Int? = nil,
        reminderWeekday: Int? = nil,
        order: Int = 0,
        unit: UnitOfMeasure? = nil,
        defaultRecordValue: Int? = nil,
        currencySymbol: String? = nil,
        reminderTimeZone: String? = nil,
        notificationPrivacyMode: NotificationPrivacyMode = .full,
        suppressWhenCompleted: Bool = true,
        additionalReminderTimes: [ReminderTime] = [],
        streakProtectionEnabled: Bool = true,
        streakProtectionThreshold: Int = 5,
        source: CalendarSource = .manual
    ) throws {
        // Validate hour and minute ranges
        if let hour = reminderHour, let minute = reminderMinute {
            guard (0 ... 23).contains(hour) else {
                throw ValidationError.invalidHour(hour)
            }
            guard (0 ... 59).contains(minute) else {
                throw ValidationError.invalidMinute(minute)
            }
        }
        self.id = id
        self.name = name
        self.color = color
        self.cadence = cadence
        self.trackingType = trackingType
        self.trackingStartedAt = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        self.dailyTarget = dailyTarget
        self.unit = unit
        self.defaultRecordValue = defaultRecordValue
        self.currencySymbol = currencySymbol
        self.isArchived = isArchived
        self.recurringReminderEnabled = recurringReminderEnabled
        self.order = order
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderWeekday = reminderWeekday
        self.reminderTimeZone = reminderTimeZone ?? TimeZone.current.identifier
        self.notificationPrivacyMode = notificationPrivacyMode
        self.suppressWhenCompleted = suppressWhenCompleted
        self.additionalReminderTimes = additionalReminderTimes
        self.streakProtectionEnabled = streakProtectionEnabled
        self.streakProtectionThreshold = streakProtectionThreshold
        self.source = source
        self.entries = entries
    }

    public func bucketDate(for date: Date) -> Date {
        switch cadence {
        case .daily:
            return LocalDayCalendar.startOfDay(for: date)
        case .weekly:
            return LocalDayCalendar.startOfWeek(for: date)
        }
    }

    public func entryKey(for date: Date) -> String {
        DayKeyFormatter.shared.string(from: bucketDate(for: date))
    }

    public func entry(for date: Date) -> CalendarEntry? {
        entries[entryKey(for: date)]
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case cadence
        case trackingType
        case trackingStartedAt
        case dailyTarget
        case unit
        case currencySymbol
        case defaultRecordValue
        case order
        case isArchived
        case recurringReminderEnabled
        case reminderHour
        case reminderMinute
        case reminderWeekday
        case reminderTimeZone
        case notificationPrivacyMode
        case suppressWhenCompleted
        case additionalReminderTimes
        case streakProtectionEnabled
        case streakProtectionThreshold
        case source
        case entries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        cadence = try container.decodeIfPresent(CalendarCadence.self, forKey: .cadence) ?? .daily
        trackingType = try container.decode(TrackingType.self, forKey: .trackingType)
        let decodedEntries = try container.decodeIfPresent([String: CalendarEntry].self, forKey: .entries) ?? [:]
        trackingStartedAt = try Self.resolveTrackingStartedAt(
            from: container,
            cadence: cadence,
            entries: decodedEntries
        )
        dailyTarget = try container.decode(Int.self, forKey: .dailyTarget)
        unit = try container.decodeIfPresent(UnitOfMeasure.self, forKey: .unit)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol)
        defaultRecordValue = try container.decodeIfPresent(Int.self, forKey: .defaultRecordValue)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        recurringReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .recurringReminderEnabled) ?? false
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute)
        reminderWeekday = try container.decodeIfPresent(Int.self, forKey: .reminderWeekday)
        reminderTimeZone = try container.decodeIfPresent(String.self, forKey: .reminderTimeZone) ?? TimeZone.current.identifier
        notificationPrivacyMode = try container.decodeIfPresent(NotificationPrivacyMode.self, forKey: .notificationPrivacyMode) ?? .full
        suppressWhenCompleted = try container.decodeIfPresent(Bool.self, forKey: .suppressWhenCompleted) ?? true
        additionalReminderTimes = try container.decodeIfPresent([ReminderTime].self, forKey: .additionalReminderTimes) ?? []
        streakProtectionEnabled = try container.decodeIfPresent(Bool.self, forKey: .streakProtectionEnabled) ?? true
        streakProtectionThreshold = try container.decodeIfPresent(Int.self, forKey: .streakProtectionThreshold) ?? 5
        source = try container.decodeIfPresent(CalendarSource.self, forKey: .source) ?? .manual
        entries = decodedEntries
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(trackingType, forKey: .trackingType)
        try container.encode(trackingStartedAt, forKey: .trackingStartedAt)
        try container.encode(dailyTarget, forKey: .dailyTarget)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(currencySymbol, forKey: .currencySymbol)
        try container.encodeIfPresent(defaultRecordValue, forKey: .defaultRecordValue)
        try container.encode(order, forKey: .order)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(recurringReminderEnabled, forKey: .recurringReminderEnabled)
        try container.encodeIfPresent(reminderHour, forKey: .reminderHour)
        try container.encodeIfPresent(reminderMinute, forKey: .reminderMinute)
        try container.encodeIfPresent(reminderWeekday, forKey: .reminderWeekday)
        try container.encodeIfPresent(reminderTimeZone, forKey: .reminderTimeZone)
        try container.encode(notificationPrivacyMode, forKey: .notificationPrivacyMode)
        try container.encode(suppressWhenCompleted, forKey: .suppressWhenCompleted)
        try container.encode(additionalReminderTimes, forKey: .additionalReminderTimes)
        try container.encode(streakProtectionEnabled, forKey: .streakProtectionEnabled)
        try container.encode(streakProtectionThreshold, forKey: .streakProtectionThreshold)
        try container.encode(source, forKey: .source)
        try container.encode(entries, forKey: .entries)
    }

    private static func resolveTrackingStartedAt(
        from container: KeyedDecodingContainer<CodingKeys>,
        cadence: CalendarCadence,
        entries: [String: CalendarEntry]
    ) throws -> Date {
        if let decoded = try container.decodeIfPresent(Date.self, forKey: .trackingStartedAt) {
            return LocalDayCalendar.startOfDay(for: decoded)
        }

        // Key absent — fall back to earliest entry date
        let startDates = entries.values.map {
            cadence == .weekly ? LocalDayCalendar.startOfWeek(for: $0.date) : LocalDayCalendar.startOfDay(for: $0.date)
        }
        guard let earliest = startDates.min() else {
            return LocalDayCalendar.startOfDay(for: Date())
        }
        return earliest
    }
}

public enum TrackingType: String, Codable, CaseIterable {
    /// A binary tracking type: done or not done (once per day).
    case binary

    /// A counter tracking type: unlimited times per day (GitHub-style count).
    case counter

    /// A multiple-daily tracking type: fixed number of times per day (with target).
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
            return String(localized: "Track a simple yes/no each day. Great for habits you either complete or skip.")
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
            .counter: DisplayRepresentation(title: LocalizedStringResource("Multiple times (unlimited) (counter)")),
            .multipleDaily: DisplayRepresentation(
                title: LocalizedStringResource("Multiple times (with target) (multipleDaily)")
            ),
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

extension CustomCalendar {
    public var isAppleHealthConnected: Bool {
        source == .appleHealthSteps
    }

    public func recomputingCompletionForTarget(_ target: Int) -> CustomCalendar {
        var updated = self
        let resolvedTarget = max(1, target)
        updated.dailyTarget = resolvedTarget
        updated.entries = entries.mapValues { entry in
            CalendarEntry(date: entry.date, count: entry.count, completed: entry.count >= resolvedTarget)
        }
        return updated
    }
}

public enum AppleHealthStepsEntryMapper {
    public static func entries(from stepCountsByDate: [Date: Int], target: Int) -> [String: CalendarEntry] {
        let resolvedTarget = max(1, target)
        return stepCountsByDate.reduce(into: [String: CalendarEntry]()) { entries, pair in
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

public enum Your365CellState: String, Codable, CaseIterable {
    case completed
    case missed
    case todayPending
    case future
    case notTracked
}

public struct Your365Cell: Codable, Hashable, Identifiable {
    public let id: String
    public let date: Date
    public let dayNumber: Int
    public let state: Your365CellState

    public init(date: Date, dayNumber: Int, state: Your365CellState) {
        let canonicalDate = LocalDayCalendar.startOfDay(for: date)
        id = DayKeyFormatter.shared.string(from: canonicalDate)
        self.date = canonicalDate
        self.dayNumber = dayNumber
        self.state = state
    }
}

public struct Your365Snapshot: Codable, Hashable {
    public let cells: [Your365Cell]
    public let trackingStartedAt: Date
    /// The cell whose date matches today, precomputed during buildCells. nil if today is not in the window.
    public let todayCell: Your365Cell?

    public init(cells: [Your365Cell], trackingStartedAt: Date, todayCell: Your365Cell? = nil) {
        self.cells = cells
        self.trackingStartedAt = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        self.todayCell = todayCell
    }

    public static func makeFirstYear(
        trackingStartedAt: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> Your365Snapshot {
        let start = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let (cells, todayCell) = buildCells(
            anchor: start,
            trackingStart: start,
            completedDates: completedDates,
            today: today
        )
        return Your365Snapshot(cells: cells, trackingStartedAt: start, todayCell: todayCell)
    }

    public static func makeLatest365Days(
        trackingStartedAt: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> Your365Snapshot {
        let start = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        guard let rangeStart = LocalDayCalendar.calendar.date(byAdding: .day, value: -364, to: todayStart) else {
            return Your365Snapshot(cells: [], trackingStartedAt: start, todayCell: nil)
        }
        let (cells, todayCell) = buildCells(
            anchor: rangeStart,
            trackingStart: start,
            completedDates: completedDates,
            today: today
        )
        return Your365Snapshot(cells: cells, trackingStartedAt: start, todayCell: todayCell)
    }

    /// Builds 365 cells starting from `anchor`.
    /// Days before `trackingStart` are marked `.notTracked` (used by the rolling-365 view).
    /// Returns the cell array and the cell matching today (if any) for O(1) lookup at call sites.
    private static func buildCells(
        anchor: Date,
        trackingStart: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> (cells: [Your365Cell], todayCell: Your365Cell?) {
        let calendar = LocalDayCalendar.calendar
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        let completed = normalizeDates(completedDates)

        var cells: [Your365Cell] = []
        var todayCell: Your365Cell? = nil
        cells.reserveCapacity(365)
        for offset in 0 ..< 365 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: anchor) else { continue }
            // date(byAdding:) with day granularity from a midnight anchor always lands at midnight — no extra startOfDay needed.
            let canonicalDate = date
            let state: Your365CellState
            if canonicalDate < trackingStart {
                state = .notTracked
            } else if canonicalDate > todayStart {
                state = .future
            } else if completed.contains(canonicalDate) {
                state = .completed
            } else if canonicalDate == todayStart {
                state = .todayPending
            } else {
                state = .missed
            }
            let cell = Your365Cell(date: canonicalDate, dayNumber: offset + 1, state: state)
            cells.append(cell)
            if canonicalDate == todayStart {
                todayCell = cell
            }
        }
        return (cells, todayCell)
    }

    private static func normalizeDates(_ dates: Set<Date>) -> Set<Date> {
        Set(dates.map { LocalDayCalendar.startOfDay(for: $0) })
    }
}

public extension CustomCalendar {
    func your365CompletedDates() -> Set<Date> {
        Set(
            entries.values.compactMap { entry in
                // Counter calendars persist `completed == false` even when `count > 0`.
                switch trackingType {
                case .binary:
                    return entry.completed ? entry.date : nil
                case .counter:
                    return entry.count > 0 ? entry.date : nil
                case .multipleDaily:
                    return entry.completed ? entry.date : nil
                }
            }
        )
    }

    /// Returns true while today is still within the first 365 days of tracking.
    func isWithinFirstYear(today: Date) -> Bool {
        let trackingStart = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        guard let maturityBoundary = LocalDayCalendar.calendar.date(byAdding: .day, value: 364, to: trackingStart) else {
            return false
        }
        return todayStart <= maturityBoundary
    }

    func makeYour365Snapshot(completedDates: Set<Date>, today: Date = Date()) -> Your365Snapshot? {
        guard cadence == .daily else { return nil }
        guard !isArchived else { return nil }

        let trackingStart = LocalDayCalendar.startOfDay(for: trackingStartedAt)

        if isWithinFirstYear(today: today) {
            return Your365Snapshot.makeFirstYear(
                trackingStartedAt: trackingStart,
                completedDates: completedDates,
                today: today
            )
        }

        return Your365Snapshot.makeLatest365Days(
            trackingStartedAt: trackingStart,
            completedDates: completedDates,
            today: today
        )
    }

    func makeFirstYearYour365Snapshot(completedDates: Set<Date>, today: Date = Date()) -> Your365Snapshot? {
        guard cadence == .daily else { return nil }
        return isArchived ? nil : Your365Snapshot.makeFirstYear(
            trackingStartedAt: trackingStartedAt,
            completedDates: completedDates,
            today: today
        )
    }
}

// MARK: - Custom Calendar Store

@available(iOS 17.0, macOS 14.0, *)
public struct CustomCalendarStoreSnapshot {
    public let calendars: [CustomCalendar]
    public let isLoading: Bool
    public let dataVersion: Int

    public init(calendars: [CustomCalendar] = [], isLoading: Bool = false, dataVersion: Int = 0) {
        self.calendars = calendars
        self.isLoading = isLoading
        self.dataVersion = dataVersion
    }

    public var activeCalendars: [CustomCalendar] {
        calendars.filter { !$0.isArchived }
    }

    public var archivedCalendars: [CustomCalendar] {
        calendars.filter { $0.isArchived }
    }

    public func calendar(id: UUID) -> CustomCalendar? {
        calendars.first(where: { $0.id == id })
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct CustomCalendarStoreDependencies {
    public let fetchCalendars: @Sendable (ModelContainer) throws -> [CustomCalendar]
    public let runMigration: @Sendable (ModelContainer) -> Void
    public let fetchCalendarShells: @Sendable (ModelContainer) throws -> [CustomCalendar]

    public init(
        fetchCalendars: @escaping @Sendable (ModelContainer) throws -> [CustomCalendar],
        runMigration: @escaping @Sendable (ModelContainer) -> Void,
        fetchCalendarShells: (@Sendable (ModelContainer) throws -> [CustomCalendar])? = nil
    ) {
        self.fetchCalendars = fetchCalendars
        self.runMigration = runMigration
        self.fetchCalendarShells = fetchCalendarShells ?? fetchCalendars
    }
}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class CustomCalendarStore: ObservableObject {
    public static let shared = CustomCalendarStore()

    @Published public private(set) var snapshot: CustomCalendarStoreSnapshot

    private let container: ModelContainer
    private let fetchCalendarsLoader: @Sendable (ModelContainer) throws -> [CustomCalendar]
    private let migrationRunner: @Sendable (ModelContainer) -> Void
    private let fetchCalendarShellsLoader: @Sendable (ModelContainer) throws -> [CustomCalendar]
    private let reloadLock = NSLock()
    private let versionLock = NSLock()
    private var latestReloadToken = UUID()
    private var latestPersistedDataVersion: Int

    public init(
        container: ModelContainer = SwiftDataManager.container,
        dependencies: CustomCalendarStoreDependencies? = nil
    ) {
        let dependencies = dependencies ?? CustomCalendarStoreDependencies(
            fetchCalendars: { container in
                try Self.fetchCalendars(container: container)
            },
            runMigration: { container in
                LegacyDataMigrator.migrateIfNeeded(container: container)
            },
            fetchCalendarShells: { container in
                try Self.fetchCalendarShells(container: container)
            }
        )
        self.container = container
        fetchCalendarsLoader = dependencies.fetchCalendars
        migrationRunner = dependencies.runMigration
        fetchCalendarShellsLoader = dependencies.fetchCalendarShells
        let initialVersion = Self.loadDataVersion()
        latestPersistedDataVersion = initialVersion
        let initialCalendars = (try? fetchCalendarShellsLoader(container)) ?? []
        snapshot = CustomCalendarStoreSnapshot(
            calendars: initialCalendars,
            isLoading: true,
            dataVersion: initialVersion
        )
        loadCalendars(showLoadingIndicator: true, targetVersion: initialVersion, runMigration: true)
    }

    @available(*, deprecated, message: "Use snapshot.calendars instead")
    public var calendars: [CustomCalendar] {
        snapshot.calendars
    }

    @available(*, deprecated, message: "Use snapshot.isLoading instead")
    public var isLoading: Bool {
        snapshot.isLoading
    }

    @available(*, deprecated, message: "Use snapshot.dataVersion instead")
    public var dataVersion: Int {
        snapshot.dataVersion
    }

    public func loadCalendars(showLoadingIndicator: Bool = true) {
        loadCalendars(showLoadingIndicator: showLoadingIndicator, targetVersion: currentPersistedDataVersion())
    }

    private func loadCalendars(showLoadingIndicator: Bool, targetVersion: Int, runMigration: Bool = false) {
        let token = UUID()
        updateLatestReloadToken(token)

        if showLoadingIndicator {
            Task { @MainActor in
                guard token == self.currentReloadToken() else { return }
                self.publishSnapshot(isLoading: true)
            }
        }

        let container = container
        let fetchCalendarsLoader = fetchCalendarsLoader
        let migrationRunner = migrationRunner
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                if runMigration {
                    migrationRunner(container)
                }

                let calendars = try fetchCalendarsLoader(container)
                await MainActor.run {
                    guard let self else { return }
                    guard token == self.currentReloadToken() else { return }
                    self.publishSnapshot(calendars: calendars, isLoading: false, dataVersion: targetVersion)
                }
            } catch {
                NSLog("Failed to load calendars from SwiftData: \(error)")
                await MainActor.run {
                    guard let self else { return }
                    guard token == self.currentReloadToken() else { return }
                    self.publishSnapshot(isLoading: false)
                }
            }
        }
    }

    // MARK: - Calendar Management

    public func addCalendar(_ calendar: CustomCalendar) {
        var newCalendar = calendar
        newCalendar.order = calendar.isArchived ? calendars.count : calendars.filter { !$0.isArchived }.count

        do {
            let context = makeContext()
            let entity = HabitCalendarEntity.make(from: newCalendar)
            context.insert(entity)

            for (dayKey, entry) in newCalendar.entries {
                let entryEntity = CalendarEntryEntity(
                    compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: entity.id, dayKey: dayKey),
                    calendarId: entity.id,
                    dayKey: dayKey,
                    date: entry.date,
                    count: entry.count,
                    completed: entry.completed
                )
                context.insert(entryEntity)
            }

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to add calendar: \(error)")
        }
    }

    public func updateCalendar(_ calendar: CustomCalendar) {
        do {
            let context = makeContext()
            let entities = fetchCalendarEntities(id: calendar.id, in: context)
            guard let entity = entities.first else { return }
            var calendarToSave = calendar
            let persistedSource = entity.calendarSource
            calendarToSave.source = persistedSource
            if persistedSource == .appleHealthSteps {
                calendarToSave.cadence = .daily
                calendarToSave.trackingType = .multipleDaily
                calendarToSave.trackingStartedAt = entity.trackingStartedAt
                calendarToSave.unit = .steps
                calendarToSave.defaultRecordValue = nil
                calendarToSave.currencySymbol = nil
            }
            if entity.isArchived, !calendar.isArchived {
                calendarToSave.order = activeCalendarCount(excluding: calendar.id, in: context)
            }
            for entity in entities {
                entity.apply(from: calendarToSave)
            }

            let existingEntries = try fetchEntries(for: calendarToSave.id, in: context)
            if persistedSource == .appleHealthSteps {
                let target = max(1, calendarToSave.dailyTarget)
                for entry in existingEntries {
                    entry.completed = entry.count >= target
                }
                try persistNormalizedCalendarOrder(in: context)
                try finishHabitMutationReloadingCalendars(in: context)
                return
            }

            var existingByKey = existingEntries.reduce(into: [String: CalendarEntryEntity]()) { partialResult, entry in
                if let existing = partialResult[entry.dayKey] {
                    if entry.date > existing.date {
                        partialResult[entry.dayKey] = entry
                    }
                } else {
                    partialResult[entry.dayKey] = entry
                }
            }

            for (key, entryModel) in calendarToSave.entries {
                if let entryEntity = existingByKey.removeValue(forKey: key) {
                    entryEntity.apply(from: entryModel, calendarId: calendarToSave.id, overrideDayKey: key)
                } else {
                    let entryEntity = CalendarEntryEntity(
                        compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendarToSave.id, dayKey: key),
                        calendarId: calendarToSave.id,
                        dayKey: key,
                        date: entryModel.date,
                        count: entryModel.count,
                        completed: entryModel.completed
                    )
                    context.insert(entryEntity)
                }
            }

            for redundant in existingByKey.values {
                context.delete(redundant)
            }

            try persistNormalizedCalendarOrder(in: context)
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to update calendar: \(error)")
        }
    }

    public func deleteCalendar(id: UUID) {
        do {
            let context = makeContext()
            let entities = fetchCalendarEntities(id: id, in: context)
            guard !entities.isEmpty else { return }
            let entries = try fetchEntries(for: id, in: context)
            for entry in entries {
                context.delete(entry)
            }
            for entity in entities {
                context.delete(entity)
            }
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to delete calendar: \(error)")
        }
    }

    @MainActor public func moveCalendar(fromOffsets indices: IndexSet, toOffset destination: Int) {
        var reordered = Self.normalizedCalendarOrder(calendars)
        reordered.move(fromOffsets: indices, toOffset: destination)
        reordered = Self.assigningContiguousOrder(to: reordered)

        do {
            let context = makeContext()
            persistCalendarOrder(reordered, in: context)
            try finishHabitMutationPublishingSnapshot(reordered, in: context)
        } catch {
            NSLog("Failed to move calendars: \(error)")
        }
    }

    @MainActor public func moveActiveCalendars(fromOffsets indices: IndexSet, toOffset destination: Int) {
        let reordered = Self.reorderedActiveCalendars(
            calendars,
            fromOffsets: indices,
            toOffset: destination
        )

        do {
            let context = makeContext()
            persistCalendarOrder(reordered, in: context)
            try finishHabitMutationPublishingSnapshot(reordered, in: context)
        } catch {
            NSLog("Failed to move active calendars: \(error)")
        }
    }

    // MARK: - Entry Management

    public func addEntry(calendarId: UUID, entry: CalendarEntry) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthStepsSource else { return }
            let cadence = CalendarCadence(rawValue: calendarEntity.cadenceRawValue) ?? .daily
            let canonicalDate = canonicalEntryDate(for: entry.date, cadence: cadence)
            let dayKey = formatDate(date: canonicalDate, cadence: cadence)
            let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)

            if let entryEntity = fetchEntry(compositeKey: compositeKey, in: context) {
                let normalizedEntry = CalendarEntry(
                    date: canonicalDate,
                    count: entry.count,
                    completed: entry.completed
                )
                entryEntity.apply(from: normalizedEntry, calendarId: calendarId, overrideDayKey: dayKey)
            } else {
                let entryEntity = CalendarEntryEntity(
                    compositeKey: compositeKey,
                    calendarId: calendarId,
                    dayKey: dayKey,
                    date: canonicalDate,
                    count: entry.count,
                    completed: entry.completed
                )
                context.insert(entryEntity)
            }

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to add entry: \(error)")
        }
    }

    @discardableResult
    public func quickLogEntry(calendarId: UUID, date: Date = Date()) -> Bool {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return false }
            guard !calendarEntity.isAppleHealthStepsSource else { return false }

            let cadence = CalendarCadence(rawValue: calendarEntity.cadenceRawValue) ?? .daily
            let trackingType = TrackingType(rawValue: calendarEntity.trackingTypeRawValue) ?? .binary
            let defaultRecordValue = max(1, calendarEntity.defaultRecordValue ?? 1)
            let dailyTarget = max(1, calendarEntity.dailyTarget)
            let canonicalDate = canonicalEntryDate(for: date, cadence: cadence)
            let dayKey = formatDate(date: canonicalDate, cadence: cadence)
            let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
            let existingEntry = fetchEntry(compositeKey: compositeKey, in: context)

            switch trackingType {
            case .binary:
                if let existingEntry {
                    context.delete(existingEntry)
                } else {
                    let entryEntity = CalendarEntryEntity(
                        compositeKey: compositeKey,
                        calendarId: calendarId,
                        dayKey: dayKey,
                        date: canonicalDate,
                        count: 1,
                        completed: true
                    )
                    context.insert(entryEntity)
                }
            case .counter:
                let newCount = (existingEntry?.count ?? 0) + defaultRecordValue
                let normalizedEntry = CalendarEntry(
                    date: canonicalDate,
                    count: newCount,
                    completed: newCount > 0
                )
                upsertEntry(
                    normalizedEntry,
                    calendarId: calendarId,
                    dayKey: dayKey,
                    compositeKey: compositeKey,
                    existingEntry: existingEntry,
                    context: context
                )
            case .multipleDaily:
                let newCount = (existingEntry?.count ?? 0) + defaultRecordValue
                let normalizedEntry = CalendarEntry(
                    date: canonicalDate,
                    count: newCount,
                    completed: newCount >= dailyTarget
                )
                upsertEntry(
                    normalizedEntry,
                    calendarId: calendarId,
                    dayKey: dayKey,
                    compositeKey: compositeKey,
                    existingEntry: existingEntry,
                    context: context
                )
            }

            try finishHabitMutationReloadingCalendars(in: context)
            return true
        } catch {
            NSLog("Failed to quick log entry: \(error)")
            return false
        }
    }

    public func getEntry(calendarId: UUID, date: Date) -> CalendarEntry? {
        let context = makeContext()
        let cadence = resolveCadence(calendarId: calendarId, in: context)
        let dayKey = formatDate(date: date, cadence: cadence)
        let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
        return fetchEntry(compositeKey: compositeKey, in: context)?.toCalendarEntry()
    }

    public func clearEntries(calendarId: UUID) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthStepsSource else { return }
            let entries = try fetchEntries(for: calendarId, in: context)
            for entry in entries {
                context.delete(entry)
            }
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to clear entries: \(error)")
        }
    }

    public func deleteEntry(calendarId: UUID, date: Date) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthStepsSource else { return }
            let cadence = resolveCadence(calendarId: calendarId, in: context)
            let dayKey = formatDate(date: date, cadence: cadence)
            let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
            guard let target = fetchEntry(compositeKey: compositeKey, in: context) else { return }
            context.delete(target)
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to delete entry: \(error)")
        }
    }

    public func replaceAppleHealthEntries(
        calendarId: UUID,
        entries replacementEntries: [String: CalendarEntry],
        from start: Date,
        through end: Date
    ) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard calendarEntity.isAppleHealthStepsSource else { return }
            let start = LocalDayCalendar.startOfDay(for: start)
            let end = LocalDayCalendar.startOfDay(for: end)
            guard start <= end else { return }

            let existingEntries = try fetchEntries(for: calendarId, in: context)
            for entry in existingEntries where entry.date >= start && entry.date <= end {
                context.delete(entry)
            }

            for (dayKey, entry) in replacementEntries {
                let canonicalDate = LocalDayCalendar.startOfDay(for: entry.date)
                guard canonicalDate >= start && canonicalDate <= end else { continue }
                let entryEntity = CalendarEntryEntity(
                    compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendarEntity.id, dayKey: dayKey),
                    calendarId: calendarEntity.id,
                    dayKey: dayKey,
                    date: canonicalDate,
                    count: entry.count,
                    completed: entry.completed
                )
                context.insert(entryEntity)
            }

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to replace Apple Health entries: \(error)")
        }
    }

    private func fetchCalendarEntity(id: UUID, in context: ModelContext) -> HabitCalendarEntity? {
        fetchCalendarEntities(id: id, in: context).first
    }

    private func fetchCalendarEntities(id: UUID, in context: ModelContext) -> [HabitCalendarEntity] {
        let predicate = #Predicate<HabitCalendarEntity> { $0.id == id }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func fetchEntries(for calendarId: UUID, in context: ModelContext) throws -> [CalendarEntryEntity] {
        let predicate = #Predicate<CalendarEntryEntity> { $0.calendarId == calendarId }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    private func fetchEntry(compositeKey: String, in context: ModelContext) -> CalendarEntryEntity? {
        let predicate = #Predicate<CalendarEntryEntity> { $0.compositeKey == compositeKey }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func activeCalendarCount(excluding excludedId: UUID, in context: ModelContext) -> Int {
        let predicate = #Predicate<HabitCalendarEntity> { !$0.isArchived && $0.id != excludedId }
        return (try? context.fetchCount(FetchDescriptor(predicate: predicate))) ?? calendars.filter {
            !$0.isArchived && $0.id != excludedId
        }.count
    }

    private func persistCalendarOrder(_ orderedCalendars: [CustomCalendar], in context: ModelContext) {
        for calendar in orderedCalendars {
            for entity in fetchCalendarEntities(id: calendar.id, in: context) {
                entity.order = calendar.order
            }
        }
    }

    private func persistNormalizedCalendarOrder(in context: ModelContext) throws {
        let entities = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
        let calendars = entities.map { $0.toCustomCalendar(entries: [:]) }
        let normalizedCalendars = Self.normalizedCalendarOrder(calendars)
        let orderById = normalizedCalendars.reduce(into: [UUID: Int]()) { result, calendar in
            result[calendar.id] = min(result[calendar.id] ?? calendar.order, calendar.order)
        }

        for entity in entities {
            if let normalizedOrder = orderById[entity.id], entity.order != normalizedOrder {
                entity.order = normalizedOrder
            }
        }
    }

    private func persistChanges(in context: ModelContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private func upsertEntry(
        _ entry: CalendarEntry,
        calendarId: UUID,
        dayKey: String,
        compositeKey: String,
        existingEntry: CalendarEntryEntity?,
        context: ModelContext
    ) {
        if let existingEntry {
            existingEntry.apply(from: entry, calendarId: calendarId, overrideDayKey: dayKey)
        } else {
            let entryEntity = CalendarEntryEntity(
                compositeKey: compositeKey,
                calendarId: calendarId,
                dayKey: dayKey,
                date: entry.date,
                count: entry.count,
                completed: entry.completed
            )
            context.insert(entryEntity)
        }
    }

    private func finishHabitMutationReloadingCalendars(in context: ModelContext) throws {
        try persistChanges(in: context)
        let nextVersion = reserveNextDataVersion()
        loadCalendars(showLoadingIndicator: false, targetVersion: nextVersion)
        WidgetReload.scheduleHabitWidgetsReload()
    }

    private func finishHabitMutationPublishingSnapshot(_ calendars: [CustomCalendar], in context: ModelContext) throws {
        try persistChanges(in: context)
        publishSnapshot(calendars: calendars)
        WidgetReload.scheduleHabitWidgetsReload()
    }

    private func makeContext() -> ModelContext {
        Self.makeContext(container: container)
    }

    private nonisolated static func makeContext(container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func resolveCadence(calendarId: UUID, in context: ModelContext) -> CalendarCadence {
        if let loaded = calendars.first(where: { $0.id == calendarId }) {
            return loaded.cadence
        }

        if let entity = fetchCalendarEntity(id: calendarId, in: context),
           let cadence = CalendarCadence(rawValue: entity.cadenceRawValue)
        {
            return cadence
        }

        return .daily
    }

    private func canonicalEntryDate(for date: Date, cadence: CalendarCadence) -> Date {
        switch cadence {
        case .daily:
            return LocalDayCalendar.startOfDay(for: date)
        case .weekly:
            return LocalDayCalendar.startOfWeek(for: date)
        }
    }

    private func formatDate(date: Date, cadence: CalendarCadence) -> String {
        DayKeyFormatter.shared.string(from: canonicalEntryDate(for: date, cadence: cadence))
    }

    private static let dataVersionKey = "CustomCalendarStore.dataVersion"
    private static let sharedDefaults = UserDefaults(suiteName: LegacyPersistenceKeys.appGroupId) ?? .standard

    private static func loadDataVersion() -> Int {
        sharedDefaults.integer(forKey: dataVersionKey)
    }

    @MainActor
    private func publishSnapshot(
        calendars: [CustomCalendar]? = nil,
        isLoading: Bool? = nil,
        dataVersion: Int? = nil
    ) {
        snapshot = CustomCalendarStoreSnapshot(
            calendars: calendars ?? snapshot.calendars,
            isLoading: isLoading ?? snapshot.isLoading,
            dataVersion: dataVersion ?? snapshot.dataVersion
        )
    }

    public nonisolated static func fetchCalendarsSnapshot(
        container: ModelContainer = SwiftDataManager.container
    ) -> [CustomCalendar] {
        (try? fetchCalendars(container: container)) ?? []
    }

    public nonisolated static func normalizedCalendarOrder(_ calendars: [CustomCalendar]) -> [CustomCalendar] {
        let activeCalendars = calendars
            .filter { !$0.isArchived }
            .sorted(by: calendarOrderSort)
        let archivedCalendars = calendars
            .filter(\.isArchived)
            .sorted(by: calendarOrderSort)

        return (activeCalendars + archivedCalendars).enumerated().map { index, calendar in
            var normalizedCalendar = calendar
            normalizedCalendar.order = index
            return normalizedCalendar
        }
    }

    public nonisolated static func reorderedActiveCalendars(
        _ calendars: [CustomCalendar],
        fromOffsets indices: IndexSet,
        toOffset destination: Int
    ) -> [CustomCalendar] {
        let normalizedCalendars = normalizedCalendarOrder(calendars)
        let activeCalendars = normalizedCalendars.filter { !$0.isArchived }
        guard !activeCalendars.isEmpty else {
            return normalizedCalendars
        }
        guard indices.allSatisfy({ activeCalendars.indices.contains($0) }) else {
            return normalizedCalendars
        }
        guard (0 ... activeCalendars.count).contains(destination) else {
            return normalizedCalendars
        }

        var reorderedActiveCalendars = activeCalendars
        reorderedActiveCalendars.move(fromOffsets: indices, toOffset: destination)

        let archivedCalendars = normalizedCalendars.filter(\.isArchived)
        return assigningContiguousOrder(to: reorderedActiveCalendars + archivedCalendars)
    }

    private nonisolated static func sortCalendars(_ calendars: [CustomCalendar]) -> [CustomCalendar] {
        normalizedCalendarOrder(calendars)
    }

    private nonisolated static func assigningContiguousOrder(to calendars: [CustomCalendar]) -> [CustomCalendar] {
        calendars.enumerated().map { index, calendar in
            var orderedCalendar = calendar
            orderedCalendar.order = index
            return orderedCalendar
        }
    }

    private nonisolated static func calendarOrderSort(_ lhs: CustomCalendar, _ rhs: CustomCalendar) -> Bool {
        if lhs.order == rhs.order {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.order < rhs.order
    }

    private func reserveNextDataVersion() -> Int {
        versionLock.lock()
        defer { versionLock.unlock() }

        latestPersistedDataVersion &+= 1
        Self.sharedDefaults.set(latestPersistedDataVersion, forKey: Self.dataVersionKey)
        return latestPersistedDataVersion
    }

    private func currentPersistedDataVersion() -> Int {
        versionLock.lock()
        defer { versionLock.unlock() }
        return latestPersistedDataVersion
    }

    private func updateLatestReloadToken(_ token: UUID) {
        reloadLock.lock()
        latestReloadToken = token
        reloadLock.unlock()
    }

    private func currentReloadToken() -> UUID {
        reloadLock.lock()
        defer { reloadLock.unlock() }
        return latestReloadToken
    }

    private nonisolated static func fetchCalendarShells(container: ModelContainer) throws -> [CustomCalendar] {
        let context = makeContext(container: container)
        let descriptor = FetchDescriptor<HabitCalendarEntity>(
            sortBy: [SortDescriptor(\HabitCalendarEntity.order)]
        )
        let calendarEntities = try context.fetch(descriptor)
        let deduplicatedCalendars = calendarEntities.reduce(into: [UUID: CustomCalendar]()) { result, entity in
            let calendar = entity.toCustomCalendar(entries: [:])
            if let existing = result[calendar.id] {
                if calendar.order < existing.order {
                    result[calendar.id] = calendar
                }
            } else {
                result[calendar.id] = calendar
            }
        }

        return normalizedCalendarOrder(Array(deduplicatedCalendars.values))
    }

    private nonisolated static func fetchCalendars(container: ModelContainer) throws -> [CustomCalendar] {
        let context = makeContext(container: container)
        let calendarsDescriptor = FetchDescriptor<HabitCalendarEntity>(
            sortBy: [SortDescriptor(\HabitCalendarEntity.order)]
        )
        let calendarEntities = try context.fetch(calendarsDescriptor)
        let entryEntities = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
        let groupedEntries = Dictionary(grouping: entryEntities, by: { $0.calendarId })

        let deduplicatedCalendars = calendarEntities.reduce(into: [UUID: CustomCalendar]()) { partialResult, entity in
            let entries = groupedEntries[entity.id, default: []]
                .reduce(into: [String: CalendarEntry]()) { partialEntries, entry in
                    let key = entry.dayKey
                    let converted = entry.toCalendarEntry()
                    if let existing = partialEntries[key] {
                        if converted.date > existing.date {
                            partialEntries[key] = converted
                        }
                    } else {
                        partialEntries[key] = converted
                    }
                }

            let calendar = entity.toCustomCalendar(entries: entries)
            if let existing = partialResult[calendar.id] {
                if calendar.order < existing.order {
                    partialResult[calendar.id] = calendar
                }
            } else {
                partialResult[calendar.id] = calendar
            }
        }

        let normalizedCalendars = Self.normalizedCalendarOrder(Array(deduplicatedCalendars.values))
        let orderById = Dictionary(uniqueKeysWithValues: normalizedCalendars.map { ($0.id, $0.order) })

        for entity in calendarEntities {
            if let normalizedOrder = orderById[entity.id], entity.order != normalizedOrder {
                entity.order = normalizedOrder
            }
        }
        if context.hasChanges {
            try context.save()
        }

        return normalizedCalendars
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class ValuationStore: ObservableObject {
    public static let shared = ValuationStore()

    @Published public var selectedYear: Int = LocalDayCalendar.calendar.component(.year, from: Date())
    @Published public private(set) var valuations: [String: DayValuation] = [:]

    private let container: ModelContainer
    private var localCalendar: Calendar {
        LocalDayCalendar.calendar
    }

    // MARK: - Date Calculations

    // TODO: Remove this function (LEGACY)
    public func dateForDay(_ day: Int) -> Date {
        let calendar = localCalendar
        let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        return calendar.date(byAdding: .day, value: day, to: startOfYear)!
    }

    public var year: Int {
        selectedYear
    }

    public var currentDayNumber: Int {
        let calendar = localCalendar
        let today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: today)

        if selectedYear > currentYear {
            return 0
        } else if selectedYear < currentYear {
            return numberOfDaysInYear
        }

        guard let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) else {
            return 0
        }

        let dayOffset = calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0
        return dayOffset + 1
    }

    public var numberOfDaysInYear: Int {
        let calendar = localCalendar
        let startOfYear = DateComponents(year: selectedYear, month: 1, day: 1)
        let endOfYear = DateComponents(year: selectedYear, month: 12, day: 31)
        guard let startDate = calendar.date(from: startOfYear),
              let endDate = calendar.date(from: endOfYear)
        else {
            return 365
        }
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 365
        return days + 1
    }

    // MARK: - Initialization

    public init(container: ModelContainer = SwiftDataManager.container) {
        self.container = container

        let container = container
        Task.detached(priority: .userInitiated) { [weak self] in
            LegacyDataMigrator.migrateIfNeeded(container: container)
            do {
                let valuations = try Self.fetchValuations(container: container)
                await MainActor.run {
                    guard let self else { return }
                    self.valuations = valuations
                }
            } catch {
                NSLog("Failed to load valuations: \(error)")
                await MainActor.run {
                    guard let self else { return }
                    self.valuations = [:]
                }
            }
        }
    }

    public func loadValuations() {
        let container = container
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let valuations = try Self.fetchValuations(container: container)
                await MainActor.run {
                    guard let self else { return }
                    self.valuations = valuations
                }
            } catch {
                NSLog("Failed to load valuations: \(error)")
                await MainActor.run {
                    guard let self else { return }
                    self.valuations = [:]
                }
            }
        }
    }

    public nonisolated static func fetchValuationsSnapshot(
        container: ModelContainer = SwiftDataManager.container
    ) -> [String: DayValuation] {
        (try? fetchValuations(container: container)) ?? [:]
    }

    public func getValuation(for date: Date) -> DayValuation? {
        let canonicalDate = LocalDayCalendar.startOfDay(for: date)
        let key = DayKeyFormatter.shared.string(from: canonicalDate)
        return valuations[key]
    }

    public func setValuation(_ mood: DayMood, for date: Date = Date()) {
        setValuation(mood, for: date, note: nil)
    }

    public func setValuation(_ mood: DayMood, for date: Date = Date(), note: String?) {
        let existingNote = getValuation(for: date)?.note
        let cleanedNote = note.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let resolvedNote = note == nil ? existingNote : (cleanedNote?.isEmpty == true ? nil : cleanedNote)
        let valuation = DayValuation(date: date, mood: mood, note: resolvedNote)
        do {
            let context = makeContext()
            if let entity = fetchEntity(dayKey: valuation.id, in: context) {
                entity.apply(from: valuation)
            } else {
                let entity = DayValuationEntity(
                    dayKey: valuation.id,
                    timestamp: valuation.timestamp,
                    moodRawValue: valuation.mood.rawValue,
                    note: valuation.note
                )
                context.insert(entity)
            }

            var newValuations = valuations
            newValuations[valuation.id] = valuation
            try finishValuationMutation(in: context, valuations: newValuations)
        } catch {
            NSLog("Failed to set valuation: \(error)")
        }
    }

    public func clearAllValuations() {
        do {
            let context = makeContext()
            let descriptor = FetchDescriptor<DayValuationEntity>()
            let entities = try context.fetch(descriptor)
            for entity in entities {
                context.delete(entity)
            }
            try finishValuationMutation(in: context, valuations: [:])
        } catch {
            NSLog("Failed to clear valuations: \(error)")
        }
    }

    private func fetchEntity(dayKey: String, in context: ModelContext) -> DayValuationEntity? {
        let predicate = #Predicate<DayValuationEntity> { $0.dayKey == dayKey }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func persistChanges(in context: ModelContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private func finishValuationMutation(in context: ModelContext, valuations: [String: DayValuation]) throws {
        try persistChanges(in: context)
        self.valuations = valuations

        #if os(iOS)
            WidgetReload.scheduleYearWidgetReload()
        #endif
    }

    private func makeContext() -> ModelContext {
        Self.makeContext(container: container)
    }

    private static func makeContext(container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private static func fetchValuations(container: ModelContainer) throws -> [String: DayValuation] {
        let context = makeContext(container: container)
        let descriptor = FetchDescriptor<DayValuationEntity>(
            sortBy: [SortDescriptor(\DayValuationEntity.dayKey)]
        )
        let entities = try context.fetch(descriptor)
        return entities.reduce(into: [String: DayValuation]()) { partialResult, entity in
            let valuation = entity.toDayValuation()
            if let existing = partialResult[entity.dayKey] {
                if valuation.timestamp > existing.timestamp {
                    partialResult[entity.dayKey] = valuation
                }
            } else {
                partialResult[entity.dayKey] = valuation
            }
        }
    }
}

public enum VisualizationType: String, Codable, AppEnum {
    case full
    case pastOnly
    case evaluatedOnly

    @available(macOS 13.0, *)
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Visualization Type"
    }

    @available(macOS 13.0, *)
    public static var caseDisplayRepresentations: [VisualizationType: DisplayRepresentation] {
        [
            .full: "Full Year",
            .pastOnly: "Past Days Only",
            .evaluatedOnly: "Evaluated Days Only",
        ]
    }
}

@available(macOS 10.15, *)
public struct MosaicChart: View {
    public let dayTypesQuantity: [DayMoodType: Int]

    @State var visualizationType: VisualizationType = .pastOnly

    public init(dayTypesQuantity: [DayMoodType: Int], visualizationType: VisualizationType? = nil) {
        self.dayTypesQuantity = dayTypesQuantity
        self.visualizationType = visualizationType ?? .pastOnly
    }

    public var sortedEntries: [(type: DayMoodType, count: Int)] {
        dayTypesQuantity.sorted { lhs, rhs in
            switch (lhs.key, rhs.key) {
            case let (.mood(m1), .mood(m2)):
                return m1.rawValue < m2.rawValue
            case (.mood, _):
                return true
            case (_, .mood):
                return false
            case (.notEvaluated, .future):
                return true
            case (.future, .notEvaluated):
                return false
            default:
                return true
            }
        }
        .map { (type: $0.key, count: $0.value) }
    }

    public var filteredEntries: [(type: DayMoodType, count: Int)] {
        sortedEntries.filter { entry in
            switch visualizationType {
            case .full: return true
            case .pastOnly: return entry.type != .future
            case .evaluatedOnly:
                if case .mood = entry.type {
                    return true
                }
                return false
            }
        }
    }

    public var body: some View {
        VStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width

                HStack(spacing: 2) {
                    ForEach(filteredEntries, id: \.type) { entry in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(entry.type.color))
                            .frame(
                                width: calculateWidth(for: entry, availableWidth: availableWidth), height: .infinity
                            )
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        )
                    )
                }
                .animation(.spring(duration: 0.3, bounce: 0.2), value: visualizationType)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: filteredEntries.map { $0.count })
            }
        }
        .frame(height: .infinity)
        .padding(.trailing)
        .onTapGesture {
            withAnimation {
                handleTap()
            }

            #if canImport(UIKit)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            #endif
        }
    }

    public func handleTap() {
        if visualizationType == .full {
            visualizationType = .pastOnly
        } else if visualizationType == .pastOnly {
            visualizationType = .evaluatedOnly
        } else if visualizationType == .evaluatedOnly {
            visualizationType = .full
        }
    }

    public func calculateWidth(for entry: (type: DayMoodType, count: Int), availableWidth: CGFloat)
        -> CGFloat
    {
        let totalCount = filteredEntries.reduce(0) { $0 + $1.count }
        return availableWidth * CGFloat(entry.count) / CGFloat(totalCount)
    }
}

@available(iOS 17.0, macOS 14.0, *)
public func updateDayTypesQuantity(store: ValuationStore) -> [DayMoodType: Int] {
    let calendar = LocalDayCalendar.calendar
    let selectedYear = store.selectedYear
    let evaluatedDays = store.valuations.values
        .filter { calendar.component(.year, from: $0.timestamp) == selectedYear }
        .reduce(into: [:]) { counts, valuation in
            counts[DayMoodType.from(valuation.mood), default: 0] += 1
        }

    let evaluatedDaysCount = evaluatedDays.values.reduce(0) { $0 + $1 }
    let notEvaluatedDays = max(0, store.currentDayNumber - evaluatedDaysCount)
    let futureDays = store.numberOfDaysInYear - store.currentDayNumber

    var quantities = evaluatedDays
    quantities[DayMoodType.notEvaluated] = notEvaluatedDays
    quantities[DayMoodType.future] = futureDays

    return quantities
}

/// Add the following error type above the CustomCalendar struct
public enum ValidationError: Error {
    case invalidHour(Int)
    case invalidMinute(Int)
}
