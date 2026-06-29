import AppIntents
import Foundation
import SharedModels

struct ShortcutCalendarOption: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    "Calendar"
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  static var defaultQuery = ShortcutCalendarQuery()
}

struct ShortcutCalendarQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [ShortcutCalendarOption] {
    let identifierSet = Set(identifiers)
    return CalendarShortcutService.selectableCalendars()
      .filter { identifierSet.contains($0.id.uuidString) }
      .map(Self.option)
  }

  func suggestedEntities() async throws -> [ShortcutCalendarOption] {
    CalendarShortcutService.selectableCalendars().map(Self.option)
  }

  private static func option(for calendar: CustomCalendar) -> ShortcutCalendarOption {
    ShortcutCalendarOption(id: calendar.id.uuidString, name: calendar.name)
  }
}

struct QuickAddCalendarIntent: AppIntent {
  static var title: LocalizedStringResource = "Quick Add Calendar"
  static var description = IntentDescription("Adds a Check-in to a selected Yearlit Calendar.")
  static var openAppWhenRun = false

  @Parameter(
    title: "Calendar",
    description: "The manual Calendar to check in.",
    requestValueDialog: IntentDialog("Which Calendar do you want to check in?")
  )
  var calendar: ShortcutCalendarOption

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let selectedCalendar = try CalendarShortcutService.calendar(for: calendar)
    let dialogPrefix = try CalendarShortcutService.checkIn(
      calendar: selectedCalendar,
      date: Date(),
      value: nil,
      store: .shared,
      source: .shortcut
    )

    return .result(dialog: "\(dialogPrefix) \(selectedCalendar.name).")
  }
}

struct CheckInCalendarIntent: AppIntent {
  static var title: LocalizedStringResource = "Check In Calendar"
  static var description = IntentDescription("Checks in a selected Yearlit Calendar for a date.")
  static var openAppWhenRun = false

  @Parameter(
    title: "Calendar",
    description: "The manual Calendar to check in.",
    requestValueDialog: IntentDialog("Which Calendar do you want to check in?")
  )
  var calendar: ShortcutCalendarOption

  @Parameter(
    title: "Value",
    description: "Amount to add for counter and target Calendars. Leave empty to use the Calendar default."
  )
  var value: Int?

  @Parameter(
    title: "Date",
    description: "Date to check in. Leave empty to use today."
  )
  var date: Date?

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let selectedCalendar = try CalendarShortcutService.calendar(for: calendar)
    let dialogPrefix = try CalendarShortcutService.checkIn(
      calendar: selectedCalendar,
      date: date ?? Date(),
      value: value,
      store: .shared,
      source: .shortcut
    )

    return .result(dialog: "\(dialogPrefix) \(selectedCalendar.name).")
  }
}

enum CalendarShortcutIntentError: Error, CustomLocalizedStringResourceConvertible {
  case calendarUnavailable
  case invalidValue

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .calendarUnavailable:
      return "Yearlit could not find that Calendar."
    case .invalidValue:
      return "The Check-in value must be greater than zero."
    }
  }
}

enum CalendarShortcutService {
  static func selectableCalendars(
    calendars: [CustomCalendar] = CustomCalendarStore.fetchCalendarsSnapshot()
  ) -> [CustomCalendar] {
    calendars.filter { calendar in
      !calendar.isArchived && calendar.source == .manual
    }
  }

  @MainActor
  static func calendar(for option: ShortcutCalendarOption) throws -> CustomCalendar {
    guard let id = UUID(uuidString: option.id),
          let calendar = selectableCalendars().first(where: { $0.id == id }) else {
      throw CalendarShortcutIntentError.calendarUnavailable
    }

    return calendar
  }

  @MainActor
  static func checkIn(
    calendar: CustomCalendar,
    date: Date,
    value: Int?,
    store: CustomCalendarStore,
    source: CalendarAnalyticsSource
  ) throws -> LocalizedStringResource {
    guard !calendar.isArchived && calendar.source == .manual else {
      throw CalendarShortcutIntentError.calendarUnavailable
    }

    switch calendar.trackingType {
    case .binary:
      saveCheckInEntry(calendar: calendar, date: date, value: nil, store: store, source: source)
      return "Checked in"
    case .counter:
      let addValue = try resolvedAddValue(value, calendar: calendar)
      saveCheckInEntry(calendar: calendar, date: date, value: addValue, store: store, source: source)
      return "Added \(addValue) to"
    case .multipleDaily:
      let addValue = try resolvedAddValue(value, calendar: calendar)
      saveCheckInEntry(calendar: calendar, date: date, value: addValue, store: store, source: source)
      return "Added \(addValue) to"
    }
  }

  private static func resolvedAddValue(_ value: Int?, calendar: CustomCalendar) throws -> Int {
    guard let addValue = calendar.resolvedCheckInValue(value) else {
      throw CalendarShortcutIntentError.invalidValue
    }
    return addValue
  }

  @MainActor
  private static func saveCheckInEntry(
    calendar: CustomCalendar,
    date: Date,
    value: Int?,
    store: CustomCalendarStore,
    source: CalendarAnalyticsSource
  ) {
    let oldEntry = store.getEntry(calendarId: calendar.id, date: date)
    guard let newEntry = calendar.checkInEntry(
      date: date,
      existingEntry: oldEntry,
      value: value
    ) else { return }
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    CalendarAnalyticsTracker.shared.trackEntryMutationDeferred(
      calendar: calendar,
      oldEntry: oldEntry,
      newEntry: newEntry,
      source: source
    )
  }
}
