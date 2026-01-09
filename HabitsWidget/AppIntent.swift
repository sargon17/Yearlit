//
//  AppIntent.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import AppIntents
import SharedModels
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

public struct ConfigurationAppIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource { "Habit Calendar Widget" }
  public static var description: IntentDescription {
    "Track your habits directly from your home screen."
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
      self.selectedCalendar = CalendarOption(
        id: calendar.id.uuidString,
        name: calendar.name
      )
    }
  }

  public init(selectedCalendar: CalendarOption? = nil) {
    self.selectedCalendar = selectedCalendar
  }
}

extension ConfigurationAppIntent {
  public static var defaultCalendar: ConfigurationAppIntent {
    let intent = ConfigurationAppIntent()
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

// public struct QuickAddIntent: AppIntent, SetValueIntent {
//   public static var title: LocalizedStringResource = "Quick Add Entry"
//   public static var description = IntentDescription("Quickly add an entry to your habit tracker")

//   @Parameter(title: "Calendar ID")
//   public var calendarId: String

//   public init() {
//     self.calendarId = ""
//   }

//   public init(calendarId: String) {
//     self.calendarId = calendarId
//   }

//   public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
//     let store = CustomCalendarStore.shared
//     let valStore = ValuationStore.shared

//     guard let calendar = store.calendars.first(where: { $0.id.uuidString == calendarId }) else {
//       return .result(value: false)
//     }

//     let today = valStore.dateForDay(valStore.currentDayNumber - 1)
//     var newEntry = CalendarEntry(date: today, count: 1, completed: true)

//     if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
//       if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
//         newEntry = CalendarEntry(
//           date: today,
//           count: existingEntry.count + 1,
//           completed: existingEntry.completed
//         )
//       } else {
//         newEntry = CalendarEntry(
//           date: today,
//           count: 1,
//           completed: !existingEntry.completed
//         )
//       }
//     }

//     store.addEntry(calendarId: calendar.id, entry: newEntry)
//     WidgetCenter.shared.reloadTimelines(ofKind: "HabitsWidget")
//     return .result(value: true)
//   }
// }
