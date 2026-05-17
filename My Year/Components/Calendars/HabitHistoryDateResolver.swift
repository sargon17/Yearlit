import Foundation
import SharedModels

enum HabitHistoryDateResolver {
  static func normalized(_ date: Date, cadence: CalendarCadence) -> Date {
    cadence == .weekly ? LocalDayCalendar.startOfWeek(for: date) : LocalDayCalendar.startOfDay(for: date)
  }

  static func today(cadence: CalendarCadence) -> Date {
    normalized(Date(), cadence: cadence)
  }

  static func earliestEntryDate(from entries: [String: CalendarEntry], cadence: CalendarCadence) -> Date? {
    entries.values.map { normalized($0.date, cadence: cadence) }.min()
  }

  static func resolvedStartDate(
    selectedDate: Date,
    earliestEntryDate: Date?,
    cadence: CalendarCadence
  ) -> Date {
    let normalizedSelectedDate = normalized(selectedDate, cadence: cadence)
    let latestStartDate = today(cadence: cadence)
    let earliestAllowedDate = earliestEntryDate ?? normalizedSelectedDate
    let earliestRequiredDate = min(normalizedSelectedDate, earliestAllowedDate)
    return min(earliestRequiredDate, latestStartDate)
  }

  static func startMovedMessage(for date: Date) -> String {
    String(
      localized: "Habit start moved to \(date.formatted(date: .abbreviated, time: .omitted)) to include your existing streak."
    )
  }
}
