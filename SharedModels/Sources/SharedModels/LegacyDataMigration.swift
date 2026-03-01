import Foundation
import SwiftData

enum LegacyPersistenceKeys {
    static let appGroupId = "group.sargon17.My-Year"
    static let calendarsKey = "customCalendars"
    static let valuationsKey = "dayValuations"
    static let migrationFlagKey = "swiftDataMigrationComplete"
    static let dayKeyMigrationFlagKey = "swiftDataDayKeyMigrationComplete"
}

@available(iOS 17.0, macOS 14.0, *)
enum LegacyDataMigrator {
    static func migrateIfNeeded(container: ModelContainer = SwiftDataManager.container) {
        guard let defaults = UserDefaults(suiteName: LegacyPersistenceKeys.appGroupId) else {
            return
        }

        // Only migrate legacy data once, unless the SwiftData store is empty.
        let alreadyMigrated = defaults.bool(forKey: LegacyPersistenceKeys.migrationFlagKey)

        let checkContext = ModelContext(container)
        checkContext.autosaveEnabled = false
        let calendarsCount = (try? checkContext.fetchCount(FetchDescriptor<HabitCalendarEntity>())) ?? 0
        let valuationsCount = (try? checkContext.fetchCount(FetchDescriptor<DayValuationEntity>())) ?? 0

        if !alreadyMigrated || (calendarsCount == 0 && valuationsCount == 0) {
            migrateLegacyData(defaults: defaults, container: container)
        }

        migrateDayKeysIfNeeded(defaults: defaults, container: container)
    }

    private static func migrateLegacyData(defaults: UserDefaults, container: ModelContainer) {
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

    private static func migrateDayKeysIfNeeded(defaults: UserDefaults, container: ModelContainer) {
        guard !defaults.bool(forKey: LegacyPersistenceKeys.dayKeyMigrationFlagKey) else { return }

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
        } catch {
            NSLog("Day key migration failed: \(error)")
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
