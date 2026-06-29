import Foundation

@available(iOS 17.0, macOS 14.0, *)
extension CustomCalendarStore {
    public nonisolated static func normalizedCalendarOrder(
        _ calendars: [CustomCalendar]
    ) -> [CustomCalendar] {
        let activeCalendars = calendars
            .filter { !$0.isArchived }
            .sorted(by: calendarOrderSort)
        let archivedCalendars = calendars
            .filter(\.isArchived)
            .sorted(by: calendarOrderSort)

        return (activeCalendars + archivedCalendars).enumerated().map { index, calendar in
            var normalizedCalendar = calendar
            normalizedCalendar.order = index
            return normalizedCalendar
        }
    }

    public nonisolated static func reorderedActiveCalendars(
        _ calendars: [CustomCalendar],
        fromOffsets indices: IndexSet,
        toOffset destination: Int
    ) -> [CustomCalendar] {
        let normalizedCalendars = normalizedCalendarOrder(calendars)
        let activeCalendars = normalizedCalendars.filter { !$0.isArchived }
        guard !activeCalendars.isEmpty else {
            return normalizedCalendars
        }
        guard indices.allSatisfy({ activeCalendars.indices.contains($0) }) else {
            return normalizedCalendars
        }
        guard (0 ... activeCalendars.count).contains(destination) else {
            return normalizedCalendars
        }

        var reorderedActiveCalendars = activeCalendars
        reorderedActiveCalendars.move(fromOffsets: indices, toOffset: destination)

        let archivedCalendars = normalizedCalendars.filter(\.isArchived)
        return assigningContiguousOrder(to: reorderedActiveCalendars + archivedCalendars)
    }

    nonisolated static func sortCalendars(_ calendars: [CustomCalendar]) -> [CustomCalendar] {
        normalizedCalendarOrder(calendars)
    }

    nonisolated static func assigningContiguousOrder(
        to calendars: [CustomCalendar]
    ) -> [CustomCalendar] {
        calendars.enumerated().map { index, calendar in
            var orderedCalendar = calendar
            orderedCalendar.order = index
            return orderedCalendar
        }
    }

    private nonisolated static func calendarOrderSort(_ lhs: CustomCalendar, _ rhs: CustomCalendar) -> Bool {
        if lhs.order == rhs.order {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.order < rhs.order
    }
}
