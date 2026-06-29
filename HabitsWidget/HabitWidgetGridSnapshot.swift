import SharedModels
import SwiftUI
import WidgetKit

struct HabitWidgetGridSnapshot {
  let days: [HabitWidgetGridDay]

  static func make(_ configuration: HabitWidgetGridSnapshotConfiguration) -> HabitWidgetGridSnapshot {
    HabitWidgetGridSnapshotBuilder(configuration: configuration).make()
  }
}

struct HabitWidgetGridSnapshotConfiguration {
  let family: WidgetFamily
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  let renderingMode: WidgetStyle.RenderingMode
}

struct HabitWidgetGridDay {
  let color: Color
  let accentable: Bool
}

struct HabitWidgetGridSnapshotBuilder {
  let family: WidgetFamily
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  let renderingMode: WidgetStyle.RenderingMode

  init(configuration: HabitWidgetGridSnapshotConfiguration) {
    family = configuration.family
    calendar = configuration.calendar
    timelineMode = configuration.timelineMode
    referenceDate = configuration.referenceDate
    backgroundColor = configuration.backgroundColor
    textPrimaryColor = configuration.textPrimaryColor
    inactiveRatio = configuration.inactiveRatio
    renderingMode = configuration.renderingMode
  }

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

  func normalizedBucketDate(for date: Date) -> Date {
    calendar?.bucketDate(for: date) ?? LocalDayCalendar.startOfDay(for: date)
  }

  private func datesForFamily(today: Date, your365Snapshot: Your365Snapshot?) -> [Date] {
    if let calendar, calendar.cadence == .weekly {
      return family == .systemSmall
        ? WidgetDateRange.recentWeeks(endingAt: today, count: 35)
        : WidgetDateRange.weeksInYear(containing: today)
    }

    if let snapshot = your365Snapshot {
      return family == .systemSmall
        ? smallYour365Dates(today: today, snapshot: snapshot)
        : snapshot.cells.map(\.date)
    }

    return family == .systemSmall
      ? WidgetDateRange.recentDays(endingAt: today, count: 35)
      : WidgetDateRange.daysInYear(containing: today)
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

}
