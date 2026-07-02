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
    static let legacyCalendarRepairFlagKey = "swiftDataLegacyCalendarRepairV1Complete"
}

@available(iOS 17.0, macOS 14.0, *)
enum LegacyDataMigrator {
    private struct TrackingStartedAtBackup: Codable {
        let createdAt: Date
        let valuesByCalendarId: [String: Date]
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
            repairCalendarsFromLegacyIfNeeded(defaults: defaults, container: container)
            migrateTrackingStartedAtIfNeeded(defaults: defaults, container: container)
            repairTrackingStartedAtIfNeeded(defaults: defaults, container: container)
        }
    }

    private static func migrateLegacyData(defaults: UserDefaults, container: ModelContainer) -> Bool {
        let context = ModelContext(container)
        context.autosaveEnabled = false

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
            return true
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
            return true
        } catch {
            // If the migration fails we keep the legacy data and try again next launch.
            NSLog("SwiftData migration failed: \(error)")
            return false
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

            var entryRecords: [(entity: CalendarEntryEntity, originalDate: Date, newKey: String, newDate: Date)] = []
            entryRecords.reserveCapacity(entryEntities.count)
            for entry in entryEntities {
                let newDate = calendar.startOfDay(for: entry.date)
                let newKey = DayKeyFormatter.shared.string(from: newDate)
                entryRecords.append((entry, entry.date, newKey, newDate))
            }

            let entryRecordById = Dictionary(
                uniqueKeysWithValues: entryRecords.map { (ObjectIdentifier($0.entity), $0) }
            )

            var chosenEntryByKey: [String: CalendarEntryEntity] = [:]
            for record in entryRecords {
                let compositeKey = CalendarEntryEntity.makeCompositeKey(
                    calendarId: record.entity.calendarId,
                    dayKey: record.newKey
                )
                if let existing = chosenEntryByKey[compositeKey] {
                    let existingRecord = entryRecordById[ObjectIdentifier(existing)]
                    let existingDate = existingRecord?.originalDate ?? existing.date
                    if record.originalDate > existingDate {
                        chosenEntryByKey[compositeKey] = record.entity
                    }
                } else {
                    chosenEntryByKey[compositeKey] = record.entity
                }
            }

            var didChange = false
            for record in entryRecords {
                let compositeKey = CalendarEntryEntity.makeCompositeKey(
                    calendarId: record.entity.calendarId,
                    dayKey: record.newKey
                )
                if chosenEntryByKey[compositeKey] !== record.entity {
                    context.delete(record.entity)
                    didChange = true
                    continue
                }

                if record.entity.dayKey != record.newKey
                    || record.entity.compositeKey != compositeKey
                    || record.entity.date != record.newDate
                {
                    record.entity.dayKey = record.newKey
                    record.entity.compositeKey = compositeKey
                    record.entity.date = record.newDate
                    didChange = true
                }
            }

            var valuationRecords: [(entity: DayValuationEntity, originalDate: Date, newKey: String, newDate: Date)] = []
            valuationRecords.reserveCapacity(valuationEntities.count)
            for valuation in valuationEntities {
                let newDate = calendar.startOfDay(for: valuation.timestamp)
                let newKey = DayKeyFormatter.shared.string(from: newDate)
                valuationRecords.append((valuation, valuation.timestamp, newKey, newDate))
            }

            let valuationRecordById = Dictionary(
                uniqueKeysWithValues: valuationRecords.map { (ObjectIdentifier($0.entity), $0) }
            )

            var chosenValuationByKey: [String: DayValuationEntity] = [:]
            for record in valuationRecords {
                if let existing = chosenValuationByKey[record.newKey] {
                    let existingRecord = valuationRecordById[ObjectIdentifier(existing)]
                    let existingDate = existingRecord?.originalDate ?? existing.timestamp
                    if record.originalDate > existingDate {
                        chosenValuationByKey[record.newKey] = record.entity
                    }
                } else {
                    chosenValuationByKey[record.newKey] = record.entity
                }
            }

            for record in valuationRecords {
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

    private static func migrateTrackingStartedAtIfNeeded(defaults: UserDefaults, container: ModelContainer) {
        guard !defaults.bool(forKey: LegacyPersistenceKeys.trackingStartedAtBackfillMigrationFlagKey) else { return }

        let context = ModelContext(container)
        context.autosaveEnabled = false

        do {
            let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
            let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
            let entriesByCalendarId = Dictionary(grouping: entries, by: { $0.calendarId })
            preserveTrackingStartedAtBackupIfNeeded(defaults: defaults, calendars: calendars)

            for calendar in calendars {
                guard let resolvedStart = earliestEntryBucketDate(
                    for: calendar,
                    entries: entriesByCalendarId[calendar.id, default: []]
                ) else { continue }

                if calendar.trackingStartedAt != resolvedStart {
                    calendar.trackingStartedAt = resolvedStart
                }
            }

            if context.hasChanges {
                try context.save()
            }
            defaults.set(true, forKey: LegacyPersistenceKeys.trackingStartedAtBackfillMigrationFlagKey)
        } catch {
            NSLog("Tracking started at backfill failed: \(error)")
        }
    }

    private static func repairTrackingStartedAtIfNeeded(defaults: UserDefaults, container: ModelContainer) {
        guard !defaults.bool(forKey: LegacyPersistenceKeys.trackingStartedAtRepairMigrationFlagKey) else { return }

        let context = ModelContext(container)
        context.autosaveEnabled = false

        do {
            let calendars = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
            let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
            let entriesByCalendarId = Dictionary(grouping: entries, by: { $0.calendarId })
            preserveTrackingStartedAtBackupIfNeeded(defaults: defaults, calendars: calendars)

            for calendar in calendars {
                guard let earliestEntryDate = earliestEntryBucketDate(
                    for: calendar,
                    entries: entriesByCalendarId[calendar.id, default: []]
                ) else { continue }

                let currentStart = LocalDayCalendar.startOfDay(for: calendar.trackingStartedAt)
                if earliestEntryDate < currentStart {
                    calendar.trackingStartedAt = earliestEntryDate
                }
            }

            if context.hasChanges {
                try context.save()
            }
            defaults.set(true, forKey: LegacyPersistenceKeys.trackingStartedAtRepairMigrationFlagKey)
        } catch {
            NSLog("Tracking started at repair failed: \(error)")
        }
    }

    private static func repairCalendarsFromLegacyIfNeeded(defaults: UserDefaults, container: ModelContainer) {
        guard !defaults.bool(forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey) else { return }
        guard let legacyCalendars = decodeLegacyCalendars(defaults: defaults), !legacyCalendars.isEmpty else {
            defaults.set(true, forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey)
            return
        }

        let context = ModelContext(container)
        context.autosaveEnabled = false

        do {
            let calendarEntities = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
            let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
            let calendarEntityById = Dictionary(grouping: calendarEntities, by: \.id).compactMapValues(\.first)
            var entryKeysByCalendarId = Dictionary(grouping: entries, by: \.calendarId).mapValues {
                Set($0.map(\.dayKey))
            }

            for legacyCalendar in legacyCalendars {
                if calendarEntityById[legacyCalendar.id] == nil {
                    context.insert(HabitCalendarEntity.make(from: legacyCalendar))
                    entryKeysByCalendarId[legacyCalendar.id] = []
                }

                for (dayKey, entry) in legacyCalendar.entries {
                    guard entryKeysByCalendarId[legacyCalendar.id, default: []].contains(dayKey) == false else {
                        continue
                    }

                    context.insert(
                        CalendarEntryEntity(
                            compositeKey: CalendarEntryEntity.makeCompositeKey(
                                calendarId: legacyCalendar.id,
                                dayKey: dayKey
                            ),
                            calendarId: legacyCalendar.id,
                            dayKey: dayKey,
                            date: entry.date,
                            count: entry.count,
                            completed: entry.completed
                        )
                    )
                    entryKeysByCalendarId[legacyCalendar.id, default: []].insert(dayKey)
                }
            }

            if context.hasChanges {
                try context.save()
            }
            defaults.set(true, forKey: LegacyPersistenceKeys.legacyCalendarRepairFlagKey)
        } catch {
            NSLog("Legacy calendar repair failed: \(error)")
        }
    }

    private static func decodeLegacyCalendars(defaults: UserDefaults) -> [CustomCalendar]? {
        guard let data = defaults.data(forKey: LegacyPersistenceKeys.calendarsKey) else { return nil }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([CustomCalendar].self, from: data) {
            return decoded
        }

        return decodeOldCalendars(from: data)
    }

    static func trackingStartedAtBackup(defaults: UserDefaults) -> [UUID: Date] {
        guard let data = defaults.data(forKey: LegacyPersistenceKeys.trackingStartedAtBackupKey),
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
                trackingStartedAt: Date(),
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
