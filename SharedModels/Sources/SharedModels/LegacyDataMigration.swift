import Foundation
import SwiftData

public enum SharedAppGroup {
  public static let id = "group.sargon17.My-Year"
}

enum LegacyPersistenceKeys {
  static let appGroupId = SharedAppGroup.id
  static let calendarsKey = "customCalendars"
  static let valuationsKey = "dayValuations"
  static let migrationFlagKey = "swiftDataMigrationComplete"
  static let dayKeyMigrationFlagKey = "swiftDataDayKeyMigrationComplete"
  static let trackingStartedAtBackfillMigrationFlagKey = "swiftDataTrackingStartedAtBackfillMigrationComplete"
  static let trackingStartedAtRepairMigrationFlagKey = "swiftDataTrackingStartedAtRepairV2Complete"
  static let trackingStartedAtBackupKey = "swiftDataTrackingStartedAtBackupV1"
}

@available(iOS 17.0, macOS 14.0, *)
enum LegacyDataMigrator {
  private struct DayKeyMigrationRecord<Entity: AnyObject> {
    let entity: Entity
    let originalDate: Date
    let newKey: String
    let newDate: Date
  }

  private struct LegacyEntryPersistenceItem {
    let entry: CalendarEntry
    let target: LegacyEntryPersistenceTarget
  }

  private struct LegacyEntryPersistenceTarget {
    let date: Date
    let dayKey: String
    let compositeKey: String
  }

  static func migrateIfNeeded(container: ModelContainer = SwiftDataManager.container) {
    guard let defaults = UserDefaults(suiteName: LegacyPersistenceKeys.appGroupId) else {
      return
    }

    migrateIfNeeded(container: container, defaults: defaults)
  }

  static func migrateIfNeeded(container: ModelContainer, defaults: UserDefaults) {
    // Only migrate legacy data once.
    let alreadyMigrated = defaults.bool(forKey: LegacyPersistenceKeys.migrationFlagKey)
    var legacyMigrationSucceeded = alreadyMigrated

    if !alreadyMigrated {
      legacyMigrationSucceeded = migrateLegacyData(defaults: defaults, container: container)
    }

    let dayKeyMigrationSucceeded = migrateDayKeysIfNeeded(defaults: defaults, container: container)

    if legacyMigrationSucceeded && dayKeyMigrationSucceeded {
      migrateTrackingStartedAtIfNeeded(defaults: defaults, container: container)
      repairTrackingStartedAtIfNeeded(defaults: defaults, container: container)
    }
  }

  private static func migrateLegacyData(defaults: UserDefaults, container: ModelContainer) -> Bool {
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let calendarsToPersist = decodeLegacyCalendars(defaults: defaults)
    let valuationsToPersist = decodeLegacyValuations(defaults: defaults)

    guard !calendarsToPersist.isEmpty || !valuationsToPersist.isEmpty else {
      defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
      return true
    }

    insertLegacyCalendars(calendarsToPersist, into: context)
    insertLegacyValuations(valuationsToPersist, into: context)

    do {
      if context.hasChanges {
        try context.save()
      }
      defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
      return true
    } catch {
      // If the migration fails we keep the legacy data and try again next launch.
      NSLog("SwiftData migration failed: \(error)")
      return false
    }
  }

  private static func decodeLegacyCalendars(defaults: UserDefaults) -> [CustomCalendar] {
    guard let data = defaults.data(forKey: LegacyPersistenceKeys.calendarsKey) else { return [] }

    if let decoded = try? JSONDecoder().decode([CustomCalendar].self, from: data) {
      return decoded
    }
    return decodeOldCalendars(from: data) ?? []
  }

  private static func decodeLegacyValuations(defaults: UserDefaults) -> [String: DayValuation] {
    guard let data = defaults.data(forKey: LegacyPersistenceKeys.valuationsKey) else { return [:] }
    return (try? JSONDecoder().decode([String: DayValuation].self, from: data)) ?? [:]
  }

  private static func insertLegacyCalendars(_ calendars: [CustomCalendar], into context: ModelContext) {
    for calendar in calendars {
      let entity = HabitCalendarEntity.make(from: calendar)
      context.insert(entity)

      for item in legacyEntriesForPersistence(calendar) {
        context.insert(
          CalendarEntryEntity(
            compositeKey: item.target.compositeKey,
            calendarId: entity.id,
            dayKey: item.target.dayKey,
            date: item.target.date,
            count: item.entry.count,
            completed: item.entry.completed
          )
        )
      }
    }
  }

  private static func legacyEntriesForPersistence(
    _ calendar: CustomCalendar
  ) -> [LegacyEntryPersistenceItem] {
    var entryByCompositeKey: [String: LegacyEntryPersistenceItem] = [:]

    for (legacyDayKey, entry) in calendar.entries {
      let target = legacyEntryPersistenceTarget(for: entry, legacyDayKey: legacyDayKey, calendar: calendar)
      if let existing = entryByCompositeKey[target.compositeKey], existing.entry.date >= entry.date {
        continue
      }
      entryByCompositeKey[target.compositeKey] = LegacyEntryPersistenceItem(entry: entry, target: target)
    }

    return Array(entryByCompositeKey.values)
  }

  private static func legacyEntryPersistenceTarget(
    for entry: CalendarEntry,
    legacyDayKey: String,
    calendar: CustomCalendar
  ) -> LegacyEntryPersistenceTarget {
    let date = legacyDate(from: legacyDayKey, cadence: calendar.cadence)
      ?? calendar.bucketDate(for: entry.date)
    let dayKey = DayKeyFormatter.shared.string(from: date)
    return LegacyEntryPersistenceTarget(
      date: date,
      dayKey: dayKey,
      compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendar.id, dayKey: dayKey)
    )
  }

  private static func legacyDate(from dayKey: String, cadence: CalendarCadence) -> Date? {
    guard let date = DayKeyFormatter.shared.date(from: dayKey) else { return nil }
    switch cadence {
    case .daily:
      return LocalDayCalendar.startOfDay(for: date)
    case .weekly:
      return LocalDayCalendar.startOfWeek(for: date)
    }
  }

  private static func insertLegacyValuations(
    _ valuations: [String: DayValuation],
    into context: ModelContext
  ) {
    for (key, valuation) in valuations {
      context.insert(
        DayValuationEntity(
          dayKey: key,
          timestamp: valuation.timestamp,
          moodRawValue: valuation.mood.rawValue
        )
      )
    }
  }

  private static func migrateDayKeysIfNeeded(defaults: UserDefaults, container: ModelContainer) -> Bool {
    guard !defaults.bool(forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey) else { return true }

    let context = ModelContext(container)
    context.autosaveEnabled = false
    let calendar = LocalDayCalendar.calendar

    do {
      let entryEntities = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
      let valuationEntities = try context.fetch(FetchDescriptor<DayValuationEntity>())
      let didChangeEntries = migrateEntryDayKeys(entryEntities, calendar: calendar, context: context)
      let didChangeValuations = migrateValuationDayKeys(
        valuationEntities,
        calendar: calendar,
        context: context
      )
      let didChange = didChangeEntries || didChangeValuations

      if didChange, context.hasChanges {
        try context.save()
      }

      defaults.set(true, forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey)
      return true
    } catch {
      NSLog("Day key migration failed: \(error)")
      return false
    }
  }

  private static func migrateEntryDayKeys(
    _ entries: [CalendarEntryEntity],
    calendar: Calendar,
    context: ModelContext
  ) -> Bool {
    let records = entryDayKeyRecords(from: entries, calendar: calendar)
    let chosenEntryByKey = chosenEntitiesByKey(records: records, key: compositeKey)

    var didChange = false
    for record in records {
      let compositeKey = compositeKey(for: record)
      if chosenEntryByKey[compositeKey] !== record.entity {
        context.delete(record.entity)
        didChange = true
        continue
      }

      let needsUpdate =
        record.entity.dayKey != record.newKey
        || record.entity.compositeKey != compositeKey
        || record.entity.date != record.newDate
      if needsUpdate {
        record.entity.dayKey = record.newKey
        record.entity.compositeKey = compositeKey
        record.entity.date = record.newDate
        didChange = true
      }
    }
    return didChange
  }

  private static func entryDayKeyRecords(
    from entries: [CalendarEntryEntity],
    calendar: Calendar
  ) -> [DayKeyMigrationRecord<CalendarEntryEntity>] {
    entries.map { entry in
      let newDate = calendar.startOfDay(for: entry.date)
      return DayKeyMigrationRecord(
        entity: entry,
        originalDate: entry.date,
        newKey: DayKeyFormatter.shared.string(from: newDate),
        newDate: newDate
      )
    }
  }

  private static func compositeKey(for record: DayKeyMigrationRecord<CalendarEntryEntity>) -> String {
    CalendarEntryEntity.makeCompositeKey(
      calendarId: record.entity.calendarId,
      dayKey: record.newKey
    )
  }

  private static func migrateValuationDayKeys(
    _ valuations: [DayValuationEntity],
    calendar: Calendar,
    context: ModelContext
  ) -> Bool {
    let records = valuationDayKeyRecords(from: valuations, calendar: calendar)
    let chosenValuationByKey = chosenEntitiesByKey(records: records, key: \.newKey)

    var didChange = false
    for record in records {
      if chosenValuationByKey[record.newKey] !== record.entity {
        context.delete(record.entity)
        didChange = true
        continue
      }

      if record.entity.dayKey != record.newKey || record.entity.timestamp != record.newDate {
        record.entity.dayKey = record.newKey
        record.entity.timestamp = record.newDate
        didChange = true
      }
    }
    return didChange
  }

  private static func valuationDayKeyRecords(
    from valuations: [DayValuationEntity],
    calendar: Calendar
  ) -> [DayKeyMigrationRecord<DayValuationEntity>] {
    valuations.map { valuation in
      let newDate = calendar.startOfDay(for: valuation.timestamp)
      return DayKeyMigrationRecord(
        entity: valuation,
        originalDate: valuation.timestamp,
        newKey: DayKeyFormatter.shared.string(from: newDate),
        newDate: newDate
      )
    }
  }

  private static func chosenEntitiesByKey<Entity: AnyObject>(
    records: [DayKeyMigrationRecord<Entity>],
    key: (DayKeyMigrationRecord<Entity>) -> String
  ) -> [String: Entity] {
    var chosenRecordByKey: [String: DayKeyMigrationRecord<Entity>] = [:]
    for record in records {
      let recordKey = key(record)
      if let existing = chosenRecordByKey[recordKey] {
        if record.originalDate > existing.originalDate {
          chosenRecordByKey[recordKey] = record
        }
      } else {
        chosenRecordByKey[recordKey] = record
      }
    }
    return chosenRecordByKey.mapValues(\.entity)
  }

}
