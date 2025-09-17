import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitCalendarEntity {
  public var id: UUID = UUID()
  public var name: String = ""
  public var color: String = ""
  public var trackingTypeRawValue: String = TrackingType.binary.rawValue
  public var dailyTarget: Int = 1
  public var unitRawValue: String?
  public var defaultRecordValue: Int?
  public var currencySymbol: String?
  public var recurringReminderEnabled: Bool = false
  public var reminderHour: Int?
  public var reminderMinute: Int?
  public var order: Int = 0

  public init(
    id: UUID = UUID(),
    name: String,
    color: String,
    trackingTypeRawValue: String,
    dailyTarget: Int,
    unitRawValue: String? = nil,
    defaultRecordValue: Int? = nil,
    currencySymbol: String? = nil,
    recurringReminderEnabled: Bool = false,
    reminderHour: Int? = nil,
    reminderMinute: Int? = nil,
    order: Int = 0
  ) {
    self.id = id
    self.name = name
    self.color = color
    self.trackingTypeRawValue = trackingTypeRawValue
    self.dailyTarget = dailyTarget
    self.unitRawValue = unitRawValue
    self.defaultRecordValue = defaultRecordValue
    self.currencySymbol = currencySymbol
    self.recurringReminderEnabled = recurringReminderEnabled
    self.reminderHour = reminderHour
    self.reminderMinute = reminderMinute
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

  public init(dayKey: String, timestamp: Date, moodRawValue: String) {
    self.dayKey = dayKey
    self.timestamp = timestamp
    self.moodRawValue = moodRawValue
  }
}

// MARK: - Model Bridges

@available(iOS 17.0, macOS 14.0, *)
extension HabitCalendarEntity {
  func toCustomCalendar(entries: [String: CalendarEntry]) -> CustomCalendar {
    let tracking = TrackingType(rawValue: trackingTypeRawValue) ?? .binary
    let unit = unitRawValue.flatMap(UnitOfMeasure.init(rawValue:))

    if let calendar = try? CustomCalendar(
      id: id,
      name: name,
      color: color,
      trackingType: tracking,
      dailyTarget: dailyTarget,
      entries: entries,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      order: order,
      unit: unit,
      defaultRecordValue: defaultRecordValue,
      currencySymbol: currencySymbol
    ) {
      return calendar
    }

    return CustomCalendar(
      id: id,
      name: name,
      color: color,
      trackingType: tracking,
      dailyTarget: dailyTarget,
      entries: entries,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderTime: nil,
      order: order,
      unit: unit,
      defaultRecordValue: defaultRecordValue,
      currencySymbol: currencySymbol
    )
  }

  func apply(from model: CustomCalendar) {
    name = model.name
    color = model.color
    trackingTypeRawValue = model.trackingType.rawValue
    dailyTarget = model.dailyTarget
    unitRawValue = model.unit?.rawValue
    defaultRecordValue = model.defaultRecordValue
    currencySymbol = model.currencySymbol
    recurringReminderEnabled = model.recurringReminderEnabled
    reminderHour = model.reminderHour
    reminderMinute = model.reminderMinute
    order = model.order
  }

  static func make(from model: CustomCalendar) -> HabitCalendarEntity {
    HabitCalendarEntity(
      id: model.id,
      name: model.name,
      color: model.color,
      trackingTypeRawValue: model.trackingType.rawValue,
      dailyTarget: model.dailyTarget,
      unitRawValue: model.unit?.rawValue,
      defaultRecordValue: model.defaultRecordValue,
      currencySymbol: model.currencySymbol,
      recurringReminderEnabled: model.recurringReminderEnabled,
      reminderHour: model.reminderHour,
      reminderMinute: model.reminderMinute,
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
    date = entry.date
    count = entry.count
    completed = entry.completed
    let resolvedDayKey = overrideDayKey ?? DayKeyFormatter.shared.string(from: entry.date)
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
    DayValuation(date: timestamp, mood: DayMood(rawValue: moodRawValue) ?? .neutral)
  }

  func apply(from valuation: DayValuation) {
    timestamp = valuation.timestamp
    moodRawValue = valuation.mood.rawValue
    dayKey = valuation.id
  }
}

@available(iOS 17.0, macOS 14.0, *)
public enum SwiftDataManager {
  public static let container: ModelContainer = {
    do {
      let appGroupId = "group.sargon17.My-Year"
      guard let groupURL = FileManager.default
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
        configurations: configuration
      )
    } catch {
      fatalError("Failed to initialise SwiftData container: \(error)")
    }
  }()
}
