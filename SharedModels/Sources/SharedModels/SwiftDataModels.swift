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
public enum SwiftDataManager {
    public static let container: ModelContainer = {
        do {
            let appGroupId = SharedAppGroup.id
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
