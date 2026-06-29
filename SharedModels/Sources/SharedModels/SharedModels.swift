import Foundation

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
    public var reminderTimeZone: String?
    public var notificationPrivacyMode: NotificationPrivacyMode = .full
    public var suppressWhenCompleted: Bool = true
    public var additionalReminderTimes: [ReminderTime] = []
    public var streakProtectionEnabled: Bool = true
    public var streakProtectionThreshold: Int = 5
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
        if let entry = entries[entryKey(for: date)] {
            return entry
        }

        let targetBucket = bucketDate(for: date)
        return entries.values
            .filter { bucketDate(for: $0.date) == targetBucket }
            .max { current, candidate in
                shouldPrefer(candidate, over: current)
            }
    }

    enum CodingKeys: String, CodingKey {
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
}

private func shouldPrefer(_ candidate: CalendarEntry, over existing: CalendarEntry) -> Bool {
    if candidate.count != existing.count {
        return candidate.count > existing.count
    }
    if candidate.completed != existing.completed {
        return candidate.completed
    }
    return candidate.date > existing.date
}

extension CustomCalendar {
    public var isAppleHealthConnected: Bool {
        appleHealthMetric != nil
    }

    public var appleHealthMetric: AppleHealthMetric? {
        AppleHealthMetric(source: source)
    }

    public func hasEntries(from start: Date, through end: Date) -> Bool {
        entries.values.contains { entry in
            entry.date >= start && entry.date <= end
        }
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
