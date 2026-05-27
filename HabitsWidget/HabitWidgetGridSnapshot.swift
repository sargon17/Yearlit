import SharedModels
import SwiftUI
import WidgetKit

struct HabitWidgetGridSnapshot {
  let days: [HabitWidgetGridDay]

  static func make(
    family: WidgetFamily,
    calendar: CustomCalendar?,
    timelineMode: CalendarTimelineMode,
    referenceDate: Date,
    backgroundColor: Color,
    textPrimaryColor: Color,
    inactiveRatio: Double,
    renderingMode: WidgetStyle.RenderingMode
  ) -> HabitWidgetGridSnapshot {
    HabitWidgetGridSnapshotBuilder(
      family: family,
      calendar: calendar,
      timelineMode: timelineMode,
      referenceDate: referenceDate,
      backgroundColor: backgroundColor,
      textPrimaryColor: textPrimaryColor,
      inactiveRatio: inactiveRatio,
      renderingMode: renderingMode
    ).make()
  }
}

struct HabitWidgetGridDay {
  let color: Color
  let accentable: Bool
}

private struct HabitWidgetGridSnapshotBuilder {
  let family: WidgetFamily
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  let renderingMode: WidgetStyle.RenderingMode

  func make() -> HabitWidgetGridSnapshot {
    let snapshot = your365Snapshot(today: referenceDate)
    let cells = snapshot?.cells ?? []
    let cellsByDate = Dictionary(uniqueKeysWithValues: cells.map { ($0.date, $0) })
    let counterDotScale = precomputeCounterDotScale()
    let days = datesForFamily(today: referenceDate, your365Snapshot: snapshot).map {
      gridDay(
        for: $0,
        today: referenceDate,
        your365CellsByDate: cellsByDate,
        counterDotScale: counterDotScale
      )
    }

    return HabitWidgetGridSnapshot(days: days)
  }

  private func precomputeCounterDotScale() -> Double {
    guard let calendar, calendar.trackingType == .counter else { return 1 }
    return precomputeRobustDotScale(for: calendar.entries.values.map(\.count))
  }

  private func gridDay(
    for date: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell],
    counterDotScale: Double
  ) -> HabitWidgetGridDay {
    let normalized = normalizedBucketDate(for: date)

    return HabitWidgetGridDay(
      color: colorForDay(
        normalized,
        today: today,
        your365CellsByDate: your365CellsByDate,
        counterDotScale: counterDotScale
      ),
      accentable: isAccentedDay(normalized, today: today)
    )
  }

  private func colorForDay(
    _ normalized: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell],
    counterDotScale: Double
  ) -> Color {
    if let cell = your365CellsByDate[normalized], cell.usesYour365OnlyColor {
      return colorForYour365Cell(cell)
    }

    return colorForCalendarDay(
      normalized,
      today: today,
      your365CellsByDate: your365CellsByDate,
      counterDotScale: counterDotScale
    )
  }

  private func colorForCalendarDay(
    _ normalized: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell],
    counterDotScale: Double
  ) -> Color {
    let normalizedToday = normalizedBucketDate(for: today)

    if renderingMode.isMonochrome {
      return monochromeColorForCalendarDay(
        normalized,
        today: normalizedToday,
        counterDotScale: counterDotScale
      )
    }

    if normalized > normalizedToday {
      return futureDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    }

    guard let calendar, let entry = calendar.entry(for: normalized) else {
      return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
    }

    switch calendar.trackingType {
    case .binary:
      return entry.completed
        ? completedColor(for: entry, today: today, counterDotScale: counterDotScale)
        : emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
    case .counter:
      guard entry.hasLoggedValue else {
        return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
      }
      let ratio = counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale)
      return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
    case .multipleDaily:
      guard entry.hasLoggedValue else {
        return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
      }
      let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
      return Color(calendar.color).opacity(opacity)
    }
  }

  private func monochromeColorForCalendarDay(
    _ normalized: Date,
    today normalizedToday: Date,
    counterDotScale: Double
  ) -> Color {
    if normalized > normalizedToday {
      return WidgetStyle.monochromeFutureDotColor()
    }

    guard let calendar, let entry = calendar.entry(for: normalized) else {
      return WidgetStyle.monochromePastDotColor()
    }

    switch calendar.trackingType {
    case .binary:
      if normalized == normalizedToday, entry.completed {
        return WidgetStyle.monochromeAccentColor()
      }
      return entry.completed
        ? WidgetStyle.monochromePrimaryColor().opacity(0.85) : WidgetStyle.monochromePastDotColor()
    case .counter:
      guard entry.hasLoggedValue else {
        return WidgetStyle.monochromePastDotColor()
      }
      let ratio = max(0.35, counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale))
      return normalized == normalizedToday
        ? WidgetStyle.monochromeAccentColor().opacity(ratio)
        : WidgetStyle.monochromePrimaryColor().opacity(ratio)
    case .multipleDaily:
      guard entry.hasLoggedValue else {
        return WidgetStyle.monochromePastDotColor()
      }
      let opacity = max(0.35, multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget))
      return normalized == normalizedToday
        ? WidgetStyle.monochromeAccentColor().opacity(opacity)
        : WidgetStyle.monochromePrimaryColor().opacity(opacity)
    }
  }

  private func isAccentedDay(_ date: Date, today: Date) -> Bool {
    guard renderingMode.isMonochrome else { return false }

    let normalized = normalizedBucketDate(for: date)
    let normalizedToday = normalizedBucketDate(for: today)

    guard normalized <= normalizedToday, let calendar, let entry = calendar.entry(for: normalized) else {
      return false
    }

    switch calendar.trackingType {
    case .binary:
      return normalized == normalizedToday && entry.completed
    case .counter, .multipleDaily:
      return normalized == normalizedToday && entry.hasLoggedValue
    }
  }

  private func emptyDotColor(for normalized: Date, today: Date, your365CellsByDate: [Date: Your365Cell]) -> Color {
    if let cell = your365CellsByDate[normalized], cell.usesYour365OnlyColor {
      return colorForYour365Cell(cell)
    }

    return normalized == normalizedBucketDate(for: today)
      ? activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
      : missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
  }

  private func normalizedBucketDate(for date: Date) -> Date {
    calendar?.bucketDate(for: date) ?? LocalDayCalendar.startOfDay(for: date)
  }

  private func datesForFamily(today: Date, your365Snapshot: Your365Snapshot?) -> [Date] {
    if let calendar, calendar.cadence == .weekly {
      return family == .systemSmall ? recentWeeks(from: today, weeks: 35) : yearWeeks(containing: today)
    }

    if let snapshot = your365Snapshot {
      return family == .systemSmall ? smallYour365Dates(today: today, snapshot: snapshot) : snapshot.cells.map(\.date)
    }

    return family == .systemSmall ? recentDates(from: today, days: 35) : yearDates(containing: today)
  }

  private func smallYour365Dates(today: Date, snapshot: Your365Snapshot) -> [Date] {
    let cells = snapshot.cells
    guard !cells.isEmpty else { return [] }

    let normalizedToday = normalizedBucketDate(for: today)
    let todayIndex =
      cells.firstIndex { $0.date == normalizedToday }
      ?? cells.indices.last { cells[$0].date <= normalizedToday }
      ?? cells.startIndex
    let endIndex = min(cells.endIndex, max(35, cells.index(after: todayIndex)))
    let startIndex = max(cells.startIndex, endIndex - 35)

    return cells[startIndex..<endIndex].map(\.date)
  }

  private func yearDates(containing date: Date) -> [Date] {
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: date)
    guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
      let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
    else {
      return []
    }

    return buildDates(from: start, to: end)
  }

  private func recentDates(from today: Date, days: Int) -> [Date] {
    let calendar = LocalDayCalendar.calendar
    let end = LocalDayCalendar.startOfDay(for: today)
    guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else {
      return [end]
    }
    return buildDates(from: start, to: end)
  }

  private func recentWeeks(from today: Date, weeks: Int) -> [Date] {
    let calendar = LocalDayCalendar.calendar
    let end = LocalDayCalendar.startOfWeek(for: today)
    guard let start = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: end) else {
      return [end]
    }
    return buildWeekDates(from: start, to: end)
  }

  private func yearWeeks(containing date: Date) -> [Date] {
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: date)
    guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
      let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
    else {
      return []
    }

    return buildWeekDates(from: LocalDayCalendar.startOfWeek(for: start), to: LocalDayCalendar.startOfWeek(for: end))
  }

  private func buildDates(from start: Date, to end: Date) -> [Date] {
    var dates: [Date] = []
    var current = start
    while current <= end {
      dates.append(current)
      guard let next = LocalDayCalendar.calendar.date(byAdding: .day, value: 1, to: current) else {
        break
      }
      current = next
    }
    return dates
  }

  private func buildWeekDates(from start: Date, to end: Date) -> [Date] {
    var dates: [Date] = []
    var current = LocalDayCalendar.startOfWeek(for: start)
    let last = LocalDayCalendar.startOfWeek(for: end)

    while current <= last {
      dates.append(current)
      guard let next = LocalDayCalendar.calendar.date(byAdding: .weekOfYear, value: 1, to: current) else {
        break
      }
      current = next
    }

    return dates
  }

  private func your365Snapshot(today: Date) -> Your365Snapshot? {
    guard shouldUseYour365Grid(), let calendar else { return nil }
    return calendar.makeYour365Snapshot(completedDates: calendar.your365CompletedDates(), today: today)
  }

  private func shouldUseYour365Grid() -> Bool {
    guard let calendar else { return false }
    return calendar.cadence == .daily
      && !calendar.isArchived
      && timelineMode.effectiveMode(for: calendar.cadence) == .your365
  }

  private func colorForYour365Cell(_ cell: Your365Cell) -> Color {
    if renderingMode.isMonochrome {
      switch cell.state {
      case .completed:
        return WidgetStyle.monochromePrimaryColor()
      case .todayPending:
        return WidgetStyle.monochromeAccentColor()
      case .missed:
        return WidgetStyle.monochromePastDotColor()
      case .future:
        return WidgetStyle.monochromeFutureDotColor()
      case .notTracked:
        return WidgetStyle.monochromePastDotColor().opacity(0.65)
      }
    }

    guard let calendar else {
      return missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }

    switch cell.state {
    case .completed:
      return Color(calendar.color)
    case .todayPending:
      return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
    case .missed:
      return missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    case .future:
      return futureDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    case .notTracked:
      return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    }
  }

  private func completedColor(for entry: CalendarEntry, today: Date, counterDotScale: Double) -> Color {
    guard let calendar else {
      return missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }

    if renderingMode.isMonochrome {
      let normalizedToday = normalizedBucketDate(for: today)
      let normalizedEntryDate = normalizedBucketDate(for: entry.date)

      switch calendar.trackingType {
      case .binary:
        return normalizedEntryDate == normalizedToday
          ? WidgetStyle.monochromeAccentColor()
          : WidgetStyle.monochromePrimaryColor()
      case .counter:
        let ratio = max(0.35, counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale))
        return normalizedEntryDate == normalizedToday
          ? WidgetStyle.monochromeAccentColor().opacity(ratio)
          : WidgetStyle.monochromePrimaryColor().opacity(ratio)
      case .multipleDaily:
        let opacity = max(0.35, multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget))
        return normalizedEntryDate == normalizedToday
          ? WidgetStyle.monochromeAccentColor().opacity(opacity)
          : WidgetStyle.monochromePrimaryColor().opacity(opacity)
      }
    }

    switch calendar.trackingType {
    case .binary:
      return Color(calendar.color)
    case .counter:
      let ratio = counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale)
      return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
    case .multipleDaily:
      let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
      return Color(calendar.color).opacity(opacity)
    }
  }
}

extension Your365Cell {
  fileprivate var usesYour365OnlyColor: Bool {
    state == .future || state == .notTracked
  }
}

extension CalendarEntry {
  fileprivate var hasLoggedValue: Bool {
    count >= 1
  }
}

extension Int {
  var hasLoggedValue: Bool {
    self > 0
  }
}

private func futureDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  WidgetStyle.futureDotColor(surface: base, text: overlay, ratio: ratio)
}

private func missedDayColor(base: Color, overlay: Color) -> Color {
  WidgetStyle.missedDotColor(surface: base, text: overlay)
}

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  WidgetStyle.inactiveDotColor(surface: base, text: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
  WidgetStyle.activeDotColor(surface: base, text: overlay, ratio: 0.12)
}
