import Foundation

@available(iOS 17.0, macOS 14.0, *)
extension HabitCalendarEntity {
  var calendarSource: CalendarSource {
    CalendarSource(rawValue: sourceRawValue ?? "") ?? .manual
  }

  var isAppleHealthSource: Bool {
    AppleHealthMetric(source: calendarSource) != nil
  }

  private var decodedAdditionalReminderTimes: [ReminderTime] {
    guard let json = additionalReminderTimesJSON,
          let data = json.data(using: .utf8)
    else {
      return []
    }
    return (try? JSONDecoder().decode([ReminderTime].self, from: data)) ?? []
  }

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
    validatedCustomCalendar(entries: entries) ?? fallbackCustomCalendar(entries: entries)
  }

  private func validatedCustomCalendar(entries: [String: CalendarEntry]) -> CustomCalendar? {
    let cadence = CalendarCadence(rawValue: cadenceRawValue) ?? .daily
    let tracking = TrackingType(rawValue: trackingTypeRawValue) ?? .binary
    let unit = unitRawValue.flatMap(UnitOfMeasure.init(rawValue:))
    let privacyMode = NotificationPrivacyMode(rawValue: notificationPrivacyModeRawValue) ?? .full
    let additionalTimes = decodedAdditionalReminderTimes
    let source = calendarSource

    return try? CustomCalendar(
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
    )
  }

  private func fallbackCustomCalendar(entries: [String: CalendarEntry]) -> CustomCalendar {
    let cadence = CalendarCadence(rawValue: cadenceRawValue) ?? .daily
    let tracking = TrackingType(rawValue: trackingTypeRawValue) ?? .binary
    let unit = unitRawValue.flatMap(UnitOfMeasure.init(rawValue:))
    let privacyMode = NotificationPrivacyMode(rawValue: notificationPrivacyModeRawValue) ?? .full
    let additionalTimes = decodedAdditionalReminderTimes
    let source = calendarSource

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
