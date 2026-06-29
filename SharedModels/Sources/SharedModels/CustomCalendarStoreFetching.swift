import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
extension CustomCalendarStore {
    public nonisolated static func fetchCalendarsSnapshot(
        container: ModelContainer = SwiftDataManager.container
    ) -> [CustomCalendar] {
        (try? fetchCalendars(container: container)) ?? []
    }

    nonisolated static func fetchCalendarShells(container: ModelContainer) throws -> [CustomCalendar] {
        let context = makeContext(container: container)
        let descriptor = FetchDescriptor<HabitCalendarEntity>(
            sortBy: [SortDescriptor(\HabitCalendarEntity.order)]
        )
        let calendarEntities = try context.fetch(descriptor)
        let deduplicatedCalendars = calendarEntities.reduce(
            into: [UUID: CustomCalendar]()
        ) { result, entity in
            let calendar = entity.toCustomCalendar(entries: [:])
            keepLowestOrderCalendar(calendar, in: &result)
        }

        return normalizedCalendarOrder(Array(deduplicatedCalendars.values))
    }

    nonisolated static func fetchCalendars(container: ModelContainer) throws -> [CustomCalendar] {
        let context = makeContext(container: container)
        let calendarsDescriptor = FetchDescriptor<HabitCalendarEntity>(
            sortBy: [SortDescriptor(\HabitCalendarEntity.order)]
        )
        let calendarEntities = try context.fetch(calendarsDescriptor)
        let entryEntities = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
        let groupedEntries = Dictionary(grouping: entryEntities, by: { $0.calendarId })

        let deduplicatedCalendars = calendarEntities.reduce(
            into: [UUID: CustomCalendar]()
        ) { result, entity in
            let entries = entriesByDayKey(for: entity, groupedEntries: groupedEntries)
            let calendar = entity.toCustomCalendar(entries: entries)
            keepLowestOrderCalendar(calendar, in: &result)
        }

        let normalizedCalendars = normalizedCalendarOrder(Array(deduplicatedCalendars.values))
        let orderById = Dictionary(uniqueKeysWithValues: normalizedCalendars.map { ($0.id, $0.order) })

        for entity in calendarEntities {
            if let normalizedOrder = orderById[entity.id], entity.order != normalizedOrder {
                entity.order = normalizedOrder
            }
        }
        if context.hasChanges {
            try context.save()
        }

        return normalizedCalendars
    }

    private nonisolated static func entriesByDayKey(
        for calendar: HabitCalendarEntity,
        groupedEntries: [UUID: [CalendarEntryEntity]]
    ) -> [String: CalendarEntry] {
        let cadence = CalendarCadence(rawValue: calendar.cadenceRawValue) ?? .daily
        let entriesByKey = groupedEntries[calendar.id, default: []]
            .reduce(into: [String: (entry: CalendarEntry, rawDate: Date)]()) { entries, entry in
                let canonicalDate = canonicalDate(for: entry.date, cadence: cadence)
                let key = DayKeyFormatter.shared.string(from: canonicalDate)
                let converted = CalendarEntry(
                    date: canonicalDate,
                    count: entry.count,
                    completed: entry.completed
                )
                guard let existing = entries[key] else {
                    entries[key] = (converted, entry.date)
                    return
                }
                if shouldPrefer(converted, rawDate: entry.date, over: existing) {
                    entries[key] = (converted, entry.date)
                }
            }
        return entriesByKey.mapValues(\.entry)
    }

    private nonisolated static func canonicalDate(for date: Date, cadence: CalendarCadence) -> Date {
        switch cadence {
        case .daily:
            return LocalDayCalendar.startOfDay(for: date)
        case .weekly:
            return LocalDayCalendar.startOfWeek(for: date)
        }
    }

    private nonisolated static func shouldPrefer(
        _ candidate: CalendarEntry,
        rawDate candidateRawDate: Date,
        over existing: (entry: CalendarEntry, rawDate: Date)
    ) -> Bool {
        if candidate.count != existing.entry.count {
            return candidate.count > existing.entry.count
        }
        if candidate.completed != existing.entry.completed {
            return candidate.completed
        }
        return candidateRawDate > existing.rawDate
    }

    private nonisolated static func keepLowestOrderCalendar(
        _ calendar: CustomCalendar,
        in calendarsById: inout [UUID: CustomCalendar]
    ) {
        guard let existing = calendarsById[calendar.id] else {
            calendarsById[calendar.id] = calendar
            return
        }
        if calendar.order < existing.order {
            calendarsById[calendar.id] = calendar
        }
    }
}
