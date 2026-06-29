import Foundation
import SharedModels

enum CustomCalendarDebugEntryFiller {
  @MainActor
  static func fill(
    snapshot: CalendarRenderSnapshot,
    today: Date,
    force: Double,
    store: CustomCalendarStore
  ) {
    #if !DEBUG
      return
    #else
    let calendar = snapshot.activeCalendar
    guard !calendar.isAppleHealthConnected else { return }

    store.clearEntries(calendarId: calendar.id)

    for date in sourceDates(from: snapshot) where date <= today && Double.random(in: 0.0...1.0) < force {
      store.addEntry(
        calendarId: calendar.id,
        entry: randomEntry(for: calendar, date: date)
      )
    }
    #endif
  }

  private static func sourceDates(from snapshot: CalendarRenderSnapshot) -> [Date] {
    snapshot.isShowingYour365
      ? snapshot.your365Snapshot?.cells.map(\.date) ?? []
      : snapshot.calendarYearGridDates
  }

  private static func randomEntry(for calendar: CustomCalendar, date: Date) -> CalendarEntry {
    switch calendar.trackingType {
    case .binary:
      return CalendarEntry(date: date, count: 1, completed: true)
    case .counter:
      let count = Int.random(in: 1...5)
      return CalendarEntry(date: date, count: count, completed: true)
    case .multipleDaily:
      let target = max(calendar.dailyTarget, 1)
      let count = Int.random(in: 1...target)
      return CalendarEntry(date: date, count: count, completed: count >= target)
    }
  }
}
