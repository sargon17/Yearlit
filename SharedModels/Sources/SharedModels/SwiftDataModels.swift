import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitCalendarEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var color: String = ""
    public var cadenceRawValue: String = CalendarCadence.daily.rawValue
    public var trackingTypeRawValue: String = TrackingType.binary.rawValue
    public var trackingStartedAt: Date = Date()
    // Legacy persisted name kept to avoid risky data migration.
    // Semantically this is the target for the calendar cadence period.
    public var dailyTarget: Int = 1
    public var unitRawValue: String?
    public var defaultRecordValue: Int?
    public var currencySymbol: String?
    public var isArchived: Bool = false
    public var recurringReminderEnabled: Bool = false
    public var reminderHour: Int?
    public var reminderMinute: Int?
    public var reminderWeekday: Int?
    public var reminderTimeZone: String?
    public var notificationPrivacyModeRawValue: String = NotificationPrivacyMode.full.rawValue
    public var suppressWhenCompleted: Bool = true
    public var additionalReminderTimesJSON: String? // JSON-encoded [ReminderTime]
    public var streakProtectionEnabled: Bool = true
    public var streakProtectionThreshold: Int = 5
    public var sourceRawValue: String?
    public var order: Int = 0

    public init(
        id: UUID = UUID(),
        name: String,
        color: String,
        cadenceRawValue: String = CalendarCadence.daily.rawValue,
        trackingTypeRawValue: String,
        dailyTarget: Int,
        trackingStartedAt: Date = Date(),
        unitRawValue: String? = nil,
        defaultRecordValue: Int? = nil,
        currencySymbol: String? = nil,
        isArchived: Bool = false,
        recurringReminderEnabled: Bool = false,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil,
        reminderWeekday: Int? = nil,
        reminderTimeZone: String? = nil,
        notificationPrivacyModeRawValue: String = NotificationPrivacyMode.full.rawValue,
        suppressWhenCompleted: Bool = true,
        additionalReminderTimesJSON: String? = nil,
        streakProtectionEnabled: Bool = true,
        streakProtectionThreshold: Int = 5,
        sourceRawValue: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.cadenceRawValue = cadenceRawValue
        self.trackingTypeRawValue = trackingTypeRawValue
        self.trackingStartedAt = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        self.dailyTarget = dailyTarget
        self.unitRawValue = unitRawValue
        self.defaultRecordValue = defaultRecordValue
        self.currencySymbol = currencySymbol
        self.isArchived = isArchived
        self.recurringReminderEnabled = recurringReminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderWeekday = reminderWeekday
        self.reminderTimeZone = reminderTimeZone
        self.notificationPrivacyModeRawValue = notificationPrivacyModeRawValue
        self.suppressWhenCompleted = suppressWhenCompleted
        self.additionalReminderTimesJSON = additionalReminderTimesJSON
        self.streakProtectionEnabled = streakProtectionEnabled
        self.streakProtectionThreshold = streakProtectionThreshold
        self.sourceRawValue = sourceRawValue
        self.order = order
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class CalendarEntryEntity {
    public var compositeKey: String = ""
    public var calendarId: UUID = UUID()
    public var dayKey: String = ""
    public var date: Date = Date()
    public var count: Int = 0
    public var completed: Bool = false

    public init(
        compositeKey: String,
        calendarId: UUID,
        dayKey: String,
        date: Date,
        count: Int,
        completed: Bool
    ) {
        self.compositeKey = compositeKey
        self.calendarId = calendarId
        self.dayKey = dayKey
        self.date = date
        self.count = count
        self.completed = completed
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class DayValuationEntity {
    public var dayKey: String = ""
    public var timestamp: Date = Date()
    public var moodRawValue: String = DayMood.neutral.rawValue
    public var note: String?

    public init(dayKey: String, timestamp: Date, moodRawValue: String, note: String? = nil) {
        self.dayKey = dayKey
        self.timestamp = timestamp
        self.moodRawValue = moodRawValue
        self.note = note
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitStackEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var prompt: String?
    public var scheduledHour: Int?
    public var scheduledMinute: Int?
    public var order: Int = 0
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String,
        prompt: String?,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        order: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitStackStepEntity {
    public var id: UUID = UUID()
    public var stackId: UUID = UUID()
    public var title: String = ""
    public var detail: String?
    public var linkedCalendarId: UUID?
    public var order: Int = 0
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        stackId: UUID,
        title: String,
        detail: String?,
        linkedCalendarId: UUID?,
        order: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.stackId = stackId
        self.title = title
        self.detail = detail
        self.linkedCalendarId = linkedCalendarId
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Model Bridges

@available(iOS 17.0, macOS 14.0, *)
extension HabitCalendarEntity {
    var calendarSource: CalendarSource {
        CalendarSource(rawValue: sourceRawValue ?? "") ?? .manual
    }

    var isAppleHealthSource: Bool {
        AppleHealthMetric(source: calendarSource) != nil
    }

    /// Helper to decode additional reminder times from JSON
    private var decodedAdditionalReminderTimes: [ReminderTime] {
        guard let json = additionalReminderTimesJSON,
              let data = json.data(using: .utf8)
        else {
            return []
        }
        return (try? JSONDecoder().decode([ReminderTime].self, from: data)) ?? []
    }

    /// Helper to encode additional reminder times to JSON
    private static func encodeAdditionalReminderTimes(_ times: [ReminderTime]) -> String? {
        guard !times.isEmpty,
              let data = try? JSONEncoder().encode(times),
              let json = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return json
    }

    func toCustomCalendar(entries: [String: CalendarEntry]) -> CustomCalendar {
        let cadence = CalendarCadence(rawValue: cadenceRawValue) ?? .daily
        let tracking = TrackingType(rawValue: trackingTypeRawValue) ?? .binary
        let unit = unitRawValue.flatMap(UnitOfMeasure.init(rawValue:))
        let privacyMode = NotificationPrivacyMode(rawValue: notificationPrivacyModeRawValue) ?? .full
        let additionalTimes = decodedAdditionalReminderTimes
        let source = calendarSource

        if let calendar = try? CustomCalendar(
            id: id,
            name: name,
            color: color,
            cadence: cadence,
            trackingType: tracking,
            trackingStartedAt: trackingStartedAt,
            dailyTarget: dailyTarget,
            entries: entries,
            isArchived: isArchived,
            recurringReminderEnabled: recurringReminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderWeekday: reminderWeekday,
            order: order,
            unit: unit,
            defaultRecordValue: defaultRecordValue,
            currencySymbol: currencySymbol,
            reminderTimeZone: reminderTimeZone,
            notificationPrivacyMode: privacyMode,
            suppressWhenCompleted: suppressWhenCompleted,
            additionalReminderTimes: additionalTimes,
            streakProtectionEnabled: streakProtectionEnabled,
            streakProtectionThreshold: streakProtectionThreshold,
            source: source
        ) {
            return calendar
        }

        return CustomCalendar(
            id: id,
            name: name,
            color: color,
            cadence: cadence,
            trackingType: tracking,
            trackingStartedAt: trackingStartedAt,
            dailyTarget: dailyTarget,
            entries: entries,
            isArchived: isArchived,
            recurringReminderEnabled: recurringReminderEnabled,
            reminderTime: nil,
            order: order,
            reminderWeekday: reminderWeekday,
            unit: unit,
            defaultRecordValue: defaultRecordValue,
            currencySymbol: currencySymbol,
            reminderTimeZone: reminderTimeZone,
            notificationPrivacyMode: privacyMode,
            suppressWhenCompleted: suppressWhenCompleted,
            additionalReminderTimes: additionalTimes,
            streakProtectionEnabled: streakProtectionEnabled,
            streakProtectionThreshold: streakProtectionThreshold,
            source: source
        )
    }

    func apply(from model: CustomCalendar) {
        name = model.name
        color = model.color
        cadenceRawValue = model.cadence.rawValue
        trackingTypeRawValue = model.trackingType.rawValue
        trackingStartedAt = LocalDayCalendar.startOfDay(for: model.trackingStartedAt)
        dailyTarget = model.dailyTarget
        unitRawValue = model.unit?.rawValue
        defaultRecordValue = model.defaultRecordValue
        currencySymbol = model.currencySymbol
        isArchived = model.isArchived
        recurringReminderEnabled = model.recurringReminderEnabled
        reminderHour = model.reminderHour
        reminderMinute = model.reminderMinute
        reminderWeekday = model.reminderWeekday
        reminderTimeZone = model.reminderTimeZone
        notificationPrivacyModeRawValue = model.notificationPrivacyMode.rawValue
        suppressWhenCompleted = model.suppressWhenCompleted
        additionalReminderTimesJSON = Self.encodeAdditionalReminderTimes(model.additionalReminderTimes)
        streakProtectionEnabled = model.streakProtectionEnabled
        streakProtectionThreshold = model.streakProtectionThreshold
        sourceRawValue = model.source.rawValue
        order = model.order
    }

    static func make(from model: CustomCalendar) -> HabitCalendarEntity {
        HabitCalendarEntity(
            id: model.id,
            name: model.name,
            color: model.color,
            cadenceRawValue: model.cadence.rawValue,
            trackingTypeRawValue: model.trackingType.rawValue,
            dailyTarget: model.dailyTarget,
            trackingStartedAt: model.trackingStartedAt,
            unitRawValue: model.unit?.rawValue,
            defaultRecordValue: model.defaultRecordValue,
            currencySymbol: model.currencySymbol,
            isArchived: model.isArchived,
            recurringReminderEnabled: model.recurringReminderEnabled,
            reminderHour: model.reminderHour,
            reminderMinute: model.reminderMinute,
            reminderWeekday: model.reminderWeekday,
            reminderTimeZone: model.reminderTimeZone,
            notificationPrivacyModeRawValue: model.notificationPrivacyMode.rawValue,
            suppressWhenCompleted: model.suppressWhenCompleted,
            additionalReminderTimesJSON: encodeAdditionalReminderTimes(model.additionalReminderTimes),
            streakProtectionEnabled: model.streakProtectionEnabled,
            streakProtectionThreshold: model.streakProtectionThreshold,
            sourceRawValue: model.source.rawValue,
            order: model.order
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension CalendarEntryEntity {
    func toCalendarEntry() -> CalendarEntry {
        CalendarEntry(date: date, count: count, completed: completed)
    }

    func apply(from entry: CalendarEntry, calendarId: UUID, overrideDayKey: String? = nil) {
        self.calendarId = calendarId
        let canonicalDate = LocalDayCalendar.startOfDay(for: entry.date)
        date = canonicalDate
        count = entry.count
        completed = entry.completed
        let resolvedDayKey = overrideDayKey ?? DayKeyFormatter.shared.string(from: canonicalDate)
        dayKey = resolvedDayKey
        compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: resolvedDayKey)
    }

    static func makeCompositeKey(calendarId: UUID, dayKey: String) -> String {
        "\(calendarId.uuidString)#\(dayKey)"
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension DayValuationEntity {
    func toDayValuation() -> DayValuation {
        DayValuation(date: timestamp, mood: DayMood(rawValue: moodRawValue) ?? .neutral, note: note)
    }

    func apply(from valuation: DayValuation) {
        timestamp = valuation.timestamp
        moodRawValue = valuation.mood.rawValue
        dayKey = valuation.id
        note = valuation.note
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension HabitStackEntity {
    func toHabitStack(steps: [HabitStackStep]) -> HabitStack {
        let normalized = HabitStack.normalizedSteps(steps, stackId: id)
        if let stack = try? HabitStack(
            id: id,
            name: name,
            prompt: prompt,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            order: order,
            steps: normalized,
            createdAt: createdAt,
            updatedAt: updatedAt
        ) {
            return stack
        }

        return HabitStack(
            uncheckedId: id,
            name: name,
            prompt: prompt,
            scheduledHour: nil,
            scheduledMinute: nil,
            order: order,
            steps: normalized,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(from stack: HabitStack) {
        name = stack.name
        prompt = stack.prompt
        scheduledHour = stack.scheduledHour
        scheduledMinute = stack.scheduledMinute
        order = stack.order
        createdAt = stack.createdAt
        updatedAt = stack.updatedAt
    }

    static func make(from stack: HabitStack) -> HabitStackEntity {
        HabitStackEntity(
            id: stack.id,
            name: stack.name,
            prompt: stack.prompt,
            scheduledHour: stack.scheduledHour,
            scheduledMinute: stack.scheduledMinute,
            order: stack.order,
            createdAt: stack.createdAt,
            updatedAt: stack.updatedAt
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension HabitStackStepEntity {
    func toHabitStackStep() -> HabitStackStep {
        HabitStackStep(
            id: id,
            stackId: stackId,
            title: title,
            detail: detail,
            linkedCalendarId: linkedCalendarId,
            order: order,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(from step: HabitStackStep, stackId: UUID) {
        id = step.id
        self.stackId = stackId
        title = step.title
        detail = step.detail
        linkedCalendarId = step.linkedCalendarId
        order = step.order
        createdAt = step.createdAt
        updatedAt = step.updatedAt
    }

    static func make(from step: HabitStackStep, stackId: UUID) -> HabitStackStepEntity {
        HabitStackStepEntity(
            id: step.id,
            stackId: stackId,
            title: step.title,
            detail: step.detail,
            linkedCalendarId: step.linkedCalendarId,
            order: step.order,
            createdAt: step.createdAt,
            updatedAt: step.updatedAt
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
public enum SwiftDataManager {
    public static let container: ModelContainer = {
        do {
            let appGroupId = "group.sargon17.My-Year"
            guard
                let groupURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
            else {
                fatalError("Unable to resolve app group container for \(appGroupId)")
            }

            let storeURL = groupURL.appendingPathComponent("SwiftDataStore.store", isDirectory: false)
            let configuration = ModelConfiguration(
                nil,
                schema: nil,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(
                for: HabitCalendarEntity.self,
                CalendarEntryEntity.self,
                DayValuationEntity.self,
                HabitStackEntity.self,
                HabitStackStepEntity.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to initialise SwiftData container: \(error)")
        }
    }()
}
