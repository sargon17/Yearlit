import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
extension LegacyDataMigrator {
  private struct TrackingStartedAtBackup: Codable {
    let createdAt: Date
    let valuesByCalendarId: [String: Date]
  }

  static func migrateTrackingStartedAtIfNeeded(defaults: UserDefaults, container: ModelContainer) {
    updateTrackingStartedAtIfNeeded(
      defaults: defaults,
      container: container,
      flagKey: LegacyPersistenceKeys.trackingStartedAtBackfillMigrationFlagKey,
      failureMessage: "Tracking started at backfill failed"
    ) { calendar, earliestEntryDate in
      calendar.trackingStartedAt != earliestEntryDate ? earliestEntryDate : nil
    }
  }

  static func repairTrackingStartedAtIfNeeded(defaults: UserDefaults, container: ModelContainer) {
    updateTrackingStartedAtIfNeeded(
      defaults: defaults,
      container: container,
      flagKey: LegacyPersistenceKeys.trackingStartedAtRepairMigrationFlagKey,
      failureMessage: "Tracking started at repair failed"
    ) { calendar, earliestEntryDate in
      let currentStart = LocalDayCalendar.startOfDay(for: calendar.trackingStartedAt)
      return earliestEntryDate < currentStart ? earliestEntryDate : nil
    }
  }

  static func trackingStartedAtBackup(defaults: UserDefaults) -> [UUID: Date] {
    guard
      let data = defaults.data(forKey: LegacyPersistenceKeys.trackingStartedAtBackupKey),
      let backup = try? JSONDecoder().decode(TrackingStartedAtBackup.self, from: data)
    else {
      return [:]
    }

    return backup.valuesByCalendarId.reduce(into: [UUID: Date]()) { partialResult, item in
      guard let calendarId = UUID(uuidString: item.key) else { return }
      partialResult[calendarId] = item.value
    }
  }

  static func restoreTrackingStartedAtFromBackup(container: ModelContainer, defaults: UserDefaults) -> Bool {
    let backup = trackingStartedAtBackup(defaults: defaults)
    guard !backup.isEmpty else { return false }

    let context = ModelContext(container)
    context.autosaveEnabled = false

    do {
      let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
      var didChange = false

      for calendar in calendars {
        guard let backedUpStart = backup[calendar.id] else { continue }
        let normalizedStart = LocalDayCalendar.startOfDay(for: backedUpStart)
        if calendar.trackingStartedAt != normalizedStart {
          calendar.trackingStartedAt = normalizedStart
          didChange = true
        }
      }

      guard didChange else { return false }
      try context.save()
      return true
    } catch {
      NSLog("Failed to restore trackingStartedAt migration backup: \(error)")
      return false
    }
  }

  private static func updateTrackingStartedAtIfNeeded(
    defaults: UserDefaults,
    container: ModelContainer,
    flagKey: String,
    failureMessage: String,
    replacementStart: (HabitCalendarEntity, Date) -> Date?
  ) {
    guard !defaults.bool(forKey: flagKey) else { return }

    let context = ModelContext(container)
    context.autosaveEnabled = false

    do {
      let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
      let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
      let entriesByCalendarId = Dictionary(grouping: entries, by: { $0.calendarId })
      preserveTrackingStartedAtBackupIfNeeded(defaults: defaults, calendars: calendars)

      for calendar in calendars {
        guard
          let earliestEntryDate = earliestEntryBucketDate(
            for: calendar,
            entries: entriesByCalendarId[calendar.id, default: []]
          )
        else { continue }

        if let replacement = replacementStart(calendar, earliestEntryDate) {
          calendar.trackingStartedAt = replacement
        }
      }

      if context.hasChanges {
        try context.save()
      }
      defaults.set(true, forKey: flagKey)
    } catch {
      NSLog("\(failureMessage): \(error)")
    }
  }

  private static func preserveTrackingStartedAtBackupIfNeeded(
    defaults: UserDefaults,
    calendars: [HabitCalendarEntity]
  ) {
    guard defaults.data(forKey: LegacyPersistenceKeys.trackingStartedAtBackupKey) == nil else { return }
    guard !calendars.isEmpty else { return }

    let valuesByCalendarId = calendars.reduce(into: [String: Date]()) { partialResult, calendar in
      partialResult[calendar.id.uuidString] = LocalDayCalendar.startOfDay(for: calendar.trackingStartedAt)
    }
    let backup = TrackingStartedAtBackup(createdAt: Date(), valuesByCalendarId: valuesByCalendarId)

    guard let data = try? JSONEncoder().encode(backup) else {
      NSLog("Failed to encode trackingStartedAt migration backup")
      return
    }

    defaults.set(data, forKey: LegacyPersistenceKeys.trackingStartedAtBackupKey)
  }

  private static func earliestEntryBucketDate(
    for calendar: HabitCalendarEntity,
    entries: [CalendarEntryEntity]
  ) -> Date? {
    entries.map {
      calendar.cadenceRawValue == CalendarCadence.weekly.rawValue
        ? LocalDayCalendar.startOfWeek(for: $0.date)
        : LocalDayCalendar.startOfDay(for: $0.date)
    }.min()
  }
}
