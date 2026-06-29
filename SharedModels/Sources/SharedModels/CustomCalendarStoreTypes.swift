import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
public struct CustomCalendarStoreSnapshot {
    public let calendars: [CustomCalendar]
    public let isLoading: Bool
    public let dataVersion: Int

    public init(calendars: [CustomCalendar] = [], isLoading: Bool = false, dataVersion: Int = 0) {
        self.calendars = calendars
        self.isLoading = isLoading
        self.dataVersion = dataVersion
    }

    public var activeCalendars: [CustomCalendar] {
        calendars.filter { !$0.isArchived }
    }

    public var archivedCalendars: [CustomCalendar] {
        calendars.filter { $0.isArchived }
    }

    public func calendar(id: UUID) -> CustomCalendar? {
        calendars.first(where: { $0.id == id })
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct CustomCalendarStoreDependencies {
    public let fetchCalendars: @Sendable (ModelContainer) throws -> [CustomCalendar]
    public let runMigration: @Sendable (ModelContainer) -> Void
    public let fetchCalendarShells: @Sendable (ModelContainer) throws -> [CustomCalendar]

    public init(
        fetchCalendars: @escaping @Sendable (ModelContainer) throws -> [CustomCalendar],
        runMigration: @escaping @Sendable (ModelContainer) -> Void,
        fetchCalendarShells: (@Sendable (ModelContainer) throws -> [CustomCalendar])? = nil
    ) {
        self.fetchCalendars = fetchCalendars
        self.runMigration = runMigration
        self.fetchCalendarShells = fetchCalendarShells ?? fetchCalendars
    }
}
