import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension CustomCalendarStore {
    public func addEntry(calendarId: UUID, entry: CalendarEntry) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthSource else { return }
            let cadence = CalendarCadence(rawValue: calendarEntity.cadenceRawValue) ?? .daily
            let target = entryPersistenceTarget(calendarId: calendarId, date: entry.date, cadence: cadence)
            let existingEntries = try fetchEntries(compositeKey: target.compositeKey, in: context)
            let normalizedEntry = CalendarEntry(
                date: target.date,
                count: entry.count,
                completed: entry.completed
            )

            upsertEntry(
                normalizedEntry,
                target: target,
                existingEntry: existingEntries.first,
                context: context
            )
            deleteEntries(existingEntries.dropFirst(), in: context)

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to add entry: \(error)")
        }
    }

    public func saveEntry(calendarId: UUID, replacing originalDate: Date, with entry: CalendarEntry) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthSource else { return }

            let cadence = CalendarCadence(rawValue: calendarEntity.cadenceRawValue) ?? .daily
            let originalTarget = entryPersistenceTarget(
                calendarId: calendarId,
                date: originalDate,
                cadence: cadence
            )
            let newTarget = entryPersistenceTarget(calendarId: calendarId, date: entry.date, cadence: cadence)

            let movedBetweenBuckets = originalTarget.compositeKey != newTarget.compositeKey
            if movedBetweenBuckets {
                let originalEntries = try fetchEntries(compositeKey: originalTarget.compositeKey, in: context)
                deleteEntries(originalEntries, in: context)
            }

            let existingEntries = try fetchEntries(compositeKey: newTarget.compositeKey, in: context)
            upsertEntry(
                CalendarEntry(date: newTarget.date, count: entry.count, completed: entry.completed),
                target: newTarget,
                existingEntry: existingEntries.first,
                context: context
            )
            deleteEntries(existingEntries.dropFirst(), in: context)

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to save entry: \(error)")
        }
    }

    public func getEntry(calendarId: UUID, date: Date) -> CalendarEntry? {
        let context = makeContext()
        let cadence = resolveCadence(calendarId: calendarId, in: context)
        let target = entryPersistenceTarget(calendarId: calendarId, date: date, cadence: cadence)
        do {
            let exactMatches = try fetchEntries(compositeKey: target.compositeKey, in: context)
            if let exactMatch = preferredEntry(from: exactMatches) {
                return exactMatch.toCalendarEntry()
            }

            return try fetchEntries(for: calendarId, in: context)
                .filter { entry in
                    let entryTarget = entryPersistenceTarget(
                        calendarId: calendarId,
                        date: entry.date,
                        cadence: cadence
                    )
                    return entryTarget.dayKey == target.dayKey
                }
                .max { current, candidate in
                    shouldPrefer(candidate, over: current)
                }?
                .toCalendarEntry()
        } catch {
            NSLog("Failed to get entry: \(error)")
            return nil
        }
    }

    public func clearEntries(calendarId: UUID) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthSource else { return }
            let entries = try fetchEntries(for: calendarId, in: context)
            for entry in entries {
                context.delete(entry)
            }
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to clear entries: \(error)")
        }
    }

    public func deleteEntry(calendarId: UUID, date: Date) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard !calendarEntity.isAppleHealthSource else { return }
            let cadence = resolveCadence(calendarId: calendarId, in: context)
            let target = entryPersistenceTarget(calendarId: calendarId, date: date, cadence: cadence)
            let entries = try fetchEntries(compositeKey: target.compositeKey, in: context)
            guard !entries.isEmpty else { return }
            deleteEntries(entries, in: context)
            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to delete entry: \(error)")
        }
    }

    public func replaceAppleHealthEntries(
        calendarId: UUID,
        entries replacementEntries: [String: CalendarEntry],
        from start: Date,
        through end: Date
    ) {
        do {
            let context = makeContext()
            guard let calendarEntity = fetchCalendarEntity(id: calendarId, in: context) else { return }
            guard calendarEntity.isAppleHealthSource else { return }
            let start = LocalDayCalendar.startOfDay(for: start)
            let end = LocalDayCalendar.startOfDay(for: end)
            guard start <= end else { return }

            let existingEntries = try fetchEntries(for: calendarId, in: context)
            for entry in existingEntries where entry.date >= start && entry.date <= end {
                context.delete(entry)
            }

            for replacement in canonicalAppleHealthReplacementEntries(
                replacementEntries,
                calendarId: calendarEntity.id,
                start: start,
                end: end
            ) {
                context.insertEntry(
                    replacement.entry,
                    target: replacement.target
                )
            }

            try finishHabitMutationReloadingCalendars(in: context)
        } catch {
            NSLog("Failed to replace Apple Health entries: \(error)")
        }
    }

    func updateAppleHealthCompletionState(
        _ entries: [CalendarEntryEntity],
        dailyTarget: Int
    ) {
        let target = max(1, dailyTarget)
        for entry in entries {
            entry.completed = entry.count >= target
        }
    }

    private func canonicalAppleHealthReplacementEntries(
        _ entries: [String: CalendarEntry],
        calendarId: UUID,
        start: Date,
        end: Date
    ) -> [(target: EntryPersistenceKey, entry: CalendarEntry)] {
        entries.values.reduce(
            into: [String: (target: EntryPersistenceKey, entry: CalendarEntry)]()
        ) { result, entry in
            let canonicalDate = LocalDayCalendar.startOfDay(for: entry.date)
            guard canonicalDate >= start && canonicalDate <= end else { return }

            let target = entryPersistenceTarget(
                calendarId: calendarId,
                date: canonicalDate,
                cadence: .daily
            )
            let replacement = CalendarEntry(
                date: target.date,
                count: entry.count,
                completed: entry.completed
            )

            guard let existing = result[target.dayKey] else {
                result[target.dayKey] = (target, replacement)
                return
            }
            let shouldReplace =
                replacement.count > existing.entry.count
                || (replacement.count == existing.entry.count
                    && replacement.completed
                    && !existing.entry.completed)
            if shouldReplace {
                result[target.dayKey] = (target, replacement)
            }
        }
        .values
        .sorted { $0.target.dayKey < $1.target.dayKey }
    }

    func syncEntries(
        for calendar: CustomCalendar,
        existingEntries: [CalendarEntryEntity],
        in context: ModelContext
    ) {
        let existingSelection = canonicalEntrySelection(existingEntries, cadence: calendar.cadence)
        var existingByKey = existingSelection.kept

        for entry in calendar.entries.values {
            let target = entryPersistenceTarget(
                calendarId: calendar.id,
                date: entry.date,
                cadence: calendar.cadence
            )
            upsertEntry(
                entry,
                target: target,
                existingEntry: existingByKey.removeValue(forKey: target.dayKey),
                context: context
            )
        }

        for redundant in existingSelection.redundant {
            context.delete(redundant)
        }
        for redundant in existingByKey.values {
            context.delete(redundant)
        }
    }

    struct EntryPersistenceKey {
        let calendarId: UUID
        let date: Date
        let dayKey: String

        var compositeKey: String {
            CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
        }
    }

    private func canonicalEntrySelection(
        _ entries: [CalendarEntryEntity],
        cadence: CalendarCadence
    ) -> (kept: [String: CalendarEntryEntity], redundant: [CalendarEntryEntity]) {
        entries.reduce(
            into: (kept: [String: CalendarEntryEntity](), redundant: [CalendarEntryEntity]())
        ) { result, entry in
            let target = entryPersistenceTarget(
                calendarId: entry.calendarId,
                date: entry.date,
                cadence: cadence
            )
            guard let existing = result.kept[target.dayKey] else {
                result.kept[target.dayKey] = entry
                return
            }
            if shouldPrefer(entry, over: existing) {
                result.kept[target.dayKey] = entry
                result.redundant.append(existing)
            } else {
                result.redundant.append(entry)
            }
        }
    }

    private func shouldPrefer(_ candidate: CalendarEntryEntity, over existing: CalendarEntryEntity) -> Bool {
        if candidate.count != existing.count {
            return candidate.count > existing.count
        }
        if candidate.completed != existing.completed {
            return candidate.completed
        }
        return candidate.date > existing.date
    }

    private func preferredEntry(from entries: [CalendarEntryEntity]) -> CalendarEntryEntity? {
        entries.max { current, candidate in
            shouldPrefer(candidate, over: current)
        }
    }

    private func upsertEntry(
        _ entry: CalendarEntry,
        target: EntryPersistenceKey,
        existingEntry: CalendarEntryEntity?,
        context: ModelContext
    ) {
        let normalizedEntry = CalendarEntry(
            date: target.date,
            count: entry.count,
            completed: entry.completed
        )
        if let existingEntry {
            existingEntry.apply(
                from: normalizedEntry,
                calendarId: target.calendarId,
                overrideDayKey: target.dayKey
            )
        } else {
            context.insertEntry(normalizedEntry, target: target)
        }
    }

    private func deleteEntries(_ entries: some Sequence<CalendarEntryEntity>, in context: ModelContext) {
        for entry in entries {
            context.delete(entry)
        }
    }

    private func resolveCadence(calendarId: UUID, in context: ModelContext) -> CalendarCadence {
        if let loaded = snapshot.calendars.first(where: { $0.id == calendarId }) {
            return loaded.cadence
        }

        if let entity = fetchCalendarEntity(id: calendarId, in: context),
           let cadence = CalendarCadence(rawValue: entity.cadenceRawValue) {
            return cadence
        }

        return .daily
    }

    private func canonicalEntryDate(for date: Date, cadence: CalendarCadence) -> Date {
        switch cadence {
        case .daily:
            return LocalDayCalendar.startOfDay(for: date)
        case .weekly:
            return LocalDayCalendar.startOfWeek(for: date)
        }
    }

    private func formatDate(date: Date, cadence: CalendarCadence) -> String {
        DayKeyFormatter.shared.string(from: canonicalEntryDate(for: date, cadence: cadence))
    }

    func entryPersistenceTarget(
        calendarId: UUID,
        date: Date,
        cadence: CalendarCadence
    ) -> EntryPersistenceKey {
        let canonicalDate = canonicalEntryDate(for: date, cadence: cadence)
        return EntryPersistenceKey(
            calendarId: calendarId,
            date: canonicalDate,
            dayKey: formatDate(date: canonicalDate, cadence: cadence)
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension ModelContext {
    func insertEntry(
        _ entry: CalendarEntry,
        target: CustomCalendarStore.EntryPersistenceKey
    ) {
        let entryEntity = CalendarEntryEntity(
            compositeKey: target.compositeKey,
            calendarId: target.calendarId,
            dayKey: target.dayKey,
            date: target.date,
            count: entry.count,
            completed: entry.completed
        )
        insert(entryEntity)
    }
}
