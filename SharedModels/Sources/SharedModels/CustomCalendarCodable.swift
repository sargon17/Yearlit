import Foundation

extension CustomCalendar {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        cadence = try container.decodeIfPresent(CalendarCadence.self, forKey: .cadence) ?? .daily
        trackingType = try container.decode(TrackingType.self, forKey: .trackingType)
        let decodedEntries = try container.decodeIfPresent(
            [String: CalendarEntry].self,
            forKey: .entries
        ) ?? [:]
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
        recurringReminderEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .recurringReminderEnabled
        ) ?? false
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute)
        reminderWeekday = try container.decodeIfPresent(Int.self, forKey: .reminderWeekday)
        reminderTimeZone = try container.decodeIfPresent(String.self, forKey: .reminderTimeZone)
            ?? TimeZone.current.identifier
        notificationPrivacyMode = try container.decodeIfPresent(
            NotificationPrivacyMode.self,
            forKey: .notificationPrivacyMode
        ) ?? .full
        suppressWhenCompleted = try container.decodeIfPresent(Bool.self, forKey: .suppressWhenCompleted)
            ?? true
        additionalReminderTimes = try container.decodeIfPresent(
            [ReminderTime].self,
            forKey: .additionalReminderTimes
        ) ?? []
        streakProtectionEnabled = try container.decodeIfPresent(Bool.self, forKey: .streakProtectionEnabled)
            ?? true
        streakProtectionThreshold = try container.decodeIfPresent(
            Int.self,
            forKey: .streakProtectionThreshold
        ) ?? 5
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

        let startDates = entries.values.map {
            cadence == .weekly
                ? LocalDayCalendar.startOfWeek(for: $0.date)
                : LocalDayCalendar.startOfDay(for: $0.date)
        }
        guard let earliest = startDates.min() else {
            return LocalDayCalendar.startOfDay(for: Date())
        }
        return earliest
    }
}
