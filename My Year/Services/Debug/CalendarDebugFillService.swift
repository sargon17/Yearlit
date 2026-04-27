import Foundation
import SharedModels

struct CalendarDebugFillService {
  @MainActor
  func fillRandomEntries(
    calendar: CustomCalendar,
    selectedYear: Int,
    currentDayNumber: Int,
    force: Double,
    store: CustomCalendarStore,
    today: Date = Date()
  ) {
    let sourceDates: [Date]
    if calendar.cadence == .weekly {
      sourceDates = getYearWeekDatesArray(for: selectedYear)
    } else {
      let localCalendar = Calendar.current
      guard
        let startOfYear = localCalendar.date(
          from: DateComponents(year: selectedYear, month: 1, day: 1)
        )
      else { return }
      sourceDates = (0..<currentDayNumber).compactMap { day in
        localCalendar.date(byAdding: .day, value: day, to: startOfYear)
      }
    }

    var entries: [String: CalendarEntry] = [:]
    for date in sourceDates where date <= today && Double.random(in: 0.0...1.0) < force {
      let entry: CalendarEntry
      switch calendar.trackingType {
      case .binary:
        entry = CalendarEntry(date: date, count: 1, completed: true)
      case .counter:
        let count = Int.random(in: 1...5)
        entry = CalendarEntry(date: date, count: count, completed: count > 0)
      case .multipleDaily:
        let count = Int.random(in: 1...max(1, calendar.dailyTarget))
        entry = CalendarEntry(
          date: date,
          count: count,
          completed: count >= calendar.dailyTarget
        )
      }
      entries[DayKeyFormatter.shared.string(from: date)] = entry
    }

    store.replaceEntries(calendarId: calendar.id, entries: entries)
  }
}
