import Foundation
import SharedModels
import SwiftUI
import UIKit

struct CalendarGridDay {
  let date: Date
  let color: Color
  let colorSaturation: CGFloat
  let isDisabled: Bool
}

struct CalendarRenderSnapshot {
  let activeCalendar: CustomCalendar
  let timelineMode: CalendarTimelineMode
  let isShowingYour365: Bool
  let your365Snapshot: Your365Snapshot?
  let calendarYearGridDates: [Date]
  let visibleGridDates: [Date]
  let your365HeaderTitle: String?
  let currentPeriodReferenceDate: Date?
  let gridDays: [CalendarGridDay]
  let cacheKey: String
}

enum CalendarRenderSnapshotCache {
  private static let lock = NSLock()
  private static var values: [String: CalendarRenderSnapshot] = [:]
  private static var keys: [String] = []
  private static let limit = 120

  static func snapshot(
    calendar: CustomCalendar,
    selectedYear: Int,
    dataVersion: Int,
    isLoading: Bool,
    timelineMode: CalendarTimelineMode,
    today: Date,
    colorScheme: ColorScheme,
    optimisticOverridesSignature: String
  ) -> CalendarRenderSnapshot {
    let cacheKey = makeCacheKey(
      calendar: calendar,
      selectedYear: selectedYear,
      dataVersion: dataVersion,
      isLoading: isLoading,
      timelineMode: timelineMode,
      today: today,
      colorScheme: colorScheme,
      optimisticOverridesSignature: optimisticOverridesSignature
    )

    lock.lock()
    if let cachedSnapshot = values[cacheKey] {
      lock.unlock()
      return cachedSnapshot
    }
    lock.unlock()

    let newSnapshot = makeSnapshot(
      calendar: calendar,
      selectedYear: selectedYear,
      timelineMode: timelineMode,
      today: today,
      cacheKey: cacheKey
    )

    lock.lock()
    if let cachedSnapshot = values[cacheKey] {
      lock.unlock()
      return cachedSnapshot
    }
    values[cacheKey] = newSnapshot
    keys.append(cacheKey)
    while keys.count > limit {
      values.removeValue(forKey: keys.removeFirst())
    }
    lock.unlock()

    return newSnapshot
  }

  private static func makeSnapshot(
    calendar: CustomCalendar,
    selectedYear: Int,
    timelineMode: CalendarTimelineMode,
    today: Date,
    cacheKey: String
  ) -> CalendarRenderSnapshot {
    let effectiveTimelineMode = timelineMode.effectiveMode(for: calendar.cadence)
    let isShowingYour365 = calendar.cadence == .daily && effectiveTimelineMode == .your365
    let calendarYearGridDates =
      calendar.cadence == .weekly
      ? getYearWeekDatesArray(for: selectedYear)
      : getYearDatesArray(for: selectedYear)
    let your365Snapshot =
      isShowingYour365
      ? calendar.makeYour365Snapshot(
        completedDates: your365CompletedDates(for: calendar),
        today: today
      )
      : nil
    let visibleGridDates = your365Snapshot?.cells.map(\.date) ?? calendarYearGridDates
    let your365HeaderTitle: String? = {
      guard let snapshot = your365Snapshot else { return nil }
      if calendar.isWithinFirstYear(today: today), let todayCell = snapshot.todayCell {
        return String(localized: "Day \(todayCell.dayNumber) of your 365")
      }
      return String(localized: "Latest 365 days")
    }()
    let currentPeriodReferenceDate: Date? = {
      if isShowingYour365 {
        return your365Snapshot?.todayCell?.date ?? today
      }
      return calendarYearGridDates.first { Calendar.current.isDate($0, inSameDayAs: today) }
    }()
    let disabledGridDates = Set(
      your365Snapshot?.cells.compactMap { cell in
        cell.state == .future || cell.state == .notTracked ? cell.date : nil
      } ?? []
    )

    return CalendarRenderSnapshot(
      activeCalendar: calendar,
      timelineMode: effectiveTimelineMode,
      isShowingYour365: isShowingYour365,
      your365Snapshot: your365Snapshot,
      calendarYearGridDates: calendarYearGridDates,
      visibleGridDates: visibleGridDates,
      your365HeaderTitle: your365HeaderTitle,
      currentPeriodReferenceDate: currentPeriodReferenceDate,
      gridDays: makeGridDays(
        calendar: calendar,
        dates: visibleGridDates,
        today: today,
        your365Snapshot: your365Snapshot,
        disabledDates: disabledGridDates
      ),
      cacheKey: cacheKey
    )
  }

  private static func makeGridDays(
    calendar: CustomCalendar,
    dates: [Date],
    today: Date,
    your365Snapshot: Your365Snapshot?,
    disabledDates: Set<Date>
  ) -> [CalendarGridDay] {
    let cellsByDate = Dictionary(uniqueKeysWithValues: your365Snapshot?.cells.map { ($0.date, $0) } ?? [])
    let counts = calendar.entries.values.map { $0.count }
    let scale = precomputeRobustDotScale(for: counts)

    return dates.map { date in
      let color: Color
      if let cell = cellsByDate[date] {
        color = colorForYour365Day(
          cell,
          calendar: calendar,
          today: today,
          precomputedScale: scale
        )
      } else {
        color = colorForDay(date, calendar: calendar, today: today, precomputedScale: scale)
      }

      return CalendarGridDay(
        date: date,
        color: color,
        colorSaturation: saturation(for: color),
        isDisabled: disabledDates.contains(date)
      )
    }
  }

  private static func saturation(for color: Color) -> CGFloat {
    let uiColor = UIColor(color)
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
      return 0
    }
    return saturation
  }

  private static func colorForYour365Day(
    _ cell: Your365Cell,
    calendar: CustomCalendar,
    today: Date,
    precomputedScale: Double
  ) -> Color {
    switch cell.state {
    case .completed, .missed, .todayPending:
      return colorForDay(
        cell.date,
        calendar: calendar,
        today: today,
        precomputedScale: precomputedScale
      )
    case .future:
      return futureDayColor()
    case .notTracked:
      return missedDayColor().opacity(0.35)
    }
  }

  private static func makeCacheKey(
    calendar: CustomCalendar,
    selectedYear: Int,
    dataVersion: Int,
    isLoading: Bool,
    timelineMode: CalendarTimelineMode,
    today: Date,
    colorScheme: ColorScheme,
    optimisticOverridesSignature: String
  ) -> String {
    [
      "calendar-render-v1",
      "\(selectedYear)",
      "\(dataVersion)",
      isLoading ? "loading" : "hydrated",
      timelineMode.rawValue,
      dayKey(for: today),
      colorScheme == .dark ? "dark" : "light",
      calendarSignature(calendar),
      optimisticOverridesSignature
    ].joined(separator: "|")
  }

  private static func calendarSignature(_ calendar: CustomCalendar) -> String {
    [
      calendar.id.uuidString,
      calendar.name,
      calendar.color,
      calendar.cadence.rawValue,
      calendar.trackingType.rawValue,
      dayKey(for: calendar.trackingStartedAt),
      "\(calendar.dailyTarget)",
      calendar.unit?.rawValue ?? "",
      calendar.currencySymbol ?? "",
      "\(calendar.recurringReminderEnabled)",
      calendar.reminderHour.map(String.init) ?? "",
      calendar.reminderMinute.map(String.init) ?? "",
      "\(calendar.entries.count)"
    ].joined(separator: "~")
  }
}
