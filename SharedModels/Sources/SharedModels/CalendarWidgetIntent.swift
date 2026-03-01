import AppIntents
import WidgetKit

public struct CalendarOption: AppEntity {
    public var id: String
    public var name: String

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Calendar"
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    public static var defaultQuery = CalendarQuery()

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct CalendarQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [CalendarOption] {
        let calendars = CustomCalendarStore.fetchCalendarsSnapshot()

        return identifiers.compactMap { id in
            if let calendar = calendars.first(where: { $0.id.uuidString == id }) {
                return CalendarOption(id: calendar.id.uuidString, name: calendar.name)
            }
            return nil
        }
    }

    public func suggestedEntities() async throws -> [CalendarOption] {
        let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
        return calendars.map { calendar in
            CalendarOption(id: calendar.id.uuidString, name: calendar.name)
        }
    }
}

public struct CalendarWidgetConfigurationIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource {
        "Calendar Widget"
    }

    public static var description: IntentDescription {
        "Display a selected habit calendar."
    }

    @Parameter(
        title: "Calendar",
        description: "Select a calendar to display",
        requestValueDialog: IntentDialog("Which calendar do you want to display?")
    )
    public var selectedCalendar: CalendarOption?

    public init() {
        let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
        if let calendar = calendars.first {
            selectedCalendar = CalendarOption(
                id: calendar.id.uuidString,
                name: calendar.name
            )
        }
    }

    public init(selectedCalendar: CalendarOption? = nil) {
        self.selectedCalendar = selectedCalendar
    }
}

public extension CalendarWidgetConfigurationIntent {
    static var defaultCalendar: CalendarWidgetConfigurationIntent {
        let intent = CalendarWidgetConfigurationIntent()
        let calendars = CustomCalendarStore.fetchCalendarsSnapshot()

        if let firstCalendar = calendars.first {
            intent.selectedCalendar = CalendarOption(
                id: firstCalendar.id.uuidString,
                name: firstCalendar.name
            )
        }
        return intent
    }
}
