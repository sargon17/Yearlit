import SharedModels

struct CalendarEntryAnalyticsTransition {
  let checkinCompleted: Bool
  let checkinRemoved: Bool
  let periodCompleted: Bool
  let periodUncompleted: Bool
  let period: String

  init(calendar: CustomCalendar, oldEntry: CalendarEntry?, newEntry: CalendarEntry?) {
    let hadProgress = Self.hasProgress(for: calendar, entry: oldEntry)
    let hasProgress = Self.hasProgress(for: calendar, entry: newEntry)
    let wasComplete = Self.isComplete(for: calendar, entry: oldEntry)
    let isComplete = Self.isComplete(for: calendar, entry: newEntry)
    let supportsPeriodCompletion = calendar.trackingType != .counter

    checkinCompleted = !hadProgress && hasProgress
    checkinRemoved = hadProgress && !hasProgress
    periodCompleted = supportsPeriodCompletion && !wasComplete && isComplete
    periodUncompleted = supportsPeriodCompletion && wasComplete && !isComplete
    period = calendar.cadence == .daily ? "day" : "week"
  }

  private static func hasProgress(for calendar: CustomCalendar, entry: CalendarEntry?) -> Bool {
    guard let entry else { return false }
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter, .multipleDaily:
      return entry.count >= 1
    }
  }

  private static func isComplete(for calendar: CustomCalendar, entry: CalendarEntry?) -> Bool {
    guard let entry else { return false }
    switch calendar.trackingType {
    case .binary, .multipleDaily:
      return entry.completed
    case .counter:
      return false
    }
  }
}
