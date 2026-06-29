import AppIntents
import SharedModels
import UIKit

struct HabitQuickAddIntent: AppIntent {
  static var title: LocalizedStringResource = "Quick Log Habit Entry"
  static var description = IntentDescription("Quickly add an entry to your habit tracker")

  @Parameter(title: "Calendar ID")
  var calendarId: String

  init() {
    calendarId = ""
  }

  init(calendarId: String) {
    self.calendarId = calendarId
  }

  func perform() async throws -> some IntentResult {
    let store = await MainActor.run { CustomCalendarStore.shared }

    guard let calendarId = UUID(uuidString: calendarId) else {
      trackQuickAdd(cadence: nil, trackingType: nil, result: "invalid_calendar")
      return .result()
    }

    let calendar = await MainActor.run {
      CustomCalendarStore.fetchCalendarsSnapshot().first(where: { $0.id == calendarId })
    }

    guard let calendar else {
      trackQuickAdd(cadence: nil, trackingType: nil, result: "invalid_calendar")
      return .result()
    }

    let quickLogSucceeded = await MainActor.run {
      let didSave = checkIn(calendar: calendar, store: store, date: Date())
      let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
      impactFeedbackGenerator.prepare()
      impactFeedbackGenerator.impactOccurred()
      return didSave
    }

    trackQuickAdd(
      cadence: calendar.cadence,
      trackingType: calendar.trackingType,
      result: quickLogSucceeded ? "success" : "failed"
    )
    return .result()
  }

  @MainActor
  private func checkIn(calendar: CustomCalendar, store: CustomCalendarStore, date: Date) -> Bool {
    guard !calendar.isArchived && calendar.source == .manual else { return false }

    let oldEntry = store.getEntry(calendarId: calendar.id, date: date)
    guard let newEntry = calendar.checkInEntry(date: date, existingEntry: oldEntry) else { return true }
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    return true
  }

  private func trackQuickAdd(
    cadence: CalendarCadence?,
    trackingType: TrackingType?,
    result: String
  ) {
    WidgetAnalyticsQueue.shared.enqueueQuickAddPerformed(properties: [
      "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
      "cadence": .string(cadence?.rawValue ?? "unknown"),
      "tracking_type": .string(trackingType?.analyticsValue ?? "unknown"),
      "result": .string(result)
    ])
  }
}
