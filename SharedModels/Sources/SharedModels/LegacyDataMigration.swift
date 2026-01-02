import Foundation
import SwiftData

enum LegacyPersistenceKeys {
  static let appGroupId = "group.sargon17.My-Year"
  static let calendarsKey = "customCalendars"
  static let valuationsKey = "dayValuations"
  static let migrationFlagKey = "swiftDataMigrationComplete"
}

@available(iOS 17.0, macOS 14.0, *)
enum LegacyDataMigrator {
  static func migrateIfNeeded(container: ModelContainer = SwiftDataManager.container) {
    guard let defaults = UserDefaults(suiteName: LegacyPersistenceKeys.appGroupId) else {
      return
    }

    // Only migrate once, unless the SwiftData store is empty.
    let alreadyMigrated = defaults.bool(forKey: LegacyPersistenceKeys.migrationFlagKey)

    let context = ModelContext(container)
    context.autosaveEnabled = false

    let calendarsCount = (try? context.fetchCount(FetchDescriptor<HabitCalendarEntity>())) ?? 0
    let valuationsCount = (try? context.fetchCount(FetchDescriptor<DayValuationEntity>())) ?? 0
    if alreadyMigrated && (calendarsCount > 0 || valuationsCount > 0) {
      return
    }

    let decoder = JSONDecoder()
    var calendarsToPersist: [CustomCalendar] = []

    if let data = defaults.data(forKey: LegacyPersistenceKeys.calendarsKey) {
      if let decoded = try? decoder.decode([CustomCalendar].self, from: data) {
        calendarsToPersist = decoded
      } else if let migrated = decodeOldCalendars(from: data) {
        calendarsToPersist = migrated
      }
    }

    var valuationsToPersist: [String: DayValuation] = [:]
    if let valuationData = defaults.data(forKey: LegacyPersistenceKeys.valuationsKey),
      let decoded = try? decoder.decode([String: DayValuation].self, from: valuationData)
    {
      valuationsToPersist = decoded
    }

    guard !calendarsToPersist.isEmpty || !valuationsToPersist.isEmpty else {
      defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
      return
    }

    for calendar in calendarsToPersist {
      let entity = HabitCalendarEntity.make(from: calendar)
      context.insert(entity)

      for (dayKey, entry) in calendar.entries {
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
    }

    for (key, valuation) in valuationsToPersist {
      let valuationEntity = DayValuationEntity(
        dayKey: key,
        timestamp: valuation.timestamp,
        moodRawValue: valuation.mood.rawValue
      )
      context.insert(valuationEntity)
    }

    do {
      if context.hasChanges {
        try context.save()
      }
      defaults.set(true, forKey: LegacyPersistenceKeys.migrationFlagKey)
    } catch {
      // If the migration fails we keep the legacy data and try again next launch.
      NSLog("SwiftData migration failed: \(error)")
    }
  }

  private static func decodeOldCalendars(from data: Data) -> [CustomCalendar]? {
    struct OldCalendar: Codable {
      let id: UUID
      var name: String
      var color: String
      var trackingType: TrackingType
      var entries: [String: CalendarEntry]
    }

    guard let oldCalendars = try? JSONDecoder().decode([OldCalendar].self, from: data) else {
      return nil
    }

    return oldCalendars.enumerated().map { index, old in
      CustomCalendar(
        id: old.id,
        name: old.name,
        color: old.color,
        trackingType: old.trackingType,
        dailyTarget: old.trackingType == .multipleDaily ? 2 : 1,
        entries: old.entries,
        isArchived: false,
        recurringReminderEnabled: false,
        reminderTime: nil,
        order: index,
        unit: nil,
        defaultRecordValue: nil,
        currencySymbol: nil
      )
    }
  }
}
