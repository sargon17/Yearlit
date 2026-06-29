import SharedModels
import SwiftUI
import WidgetKit

#Preview("Daily Calendar Year") {
  previewWidget(
    HabitWidgetPreviewFixture(
      calendar: previewDailyCalendar(),
      timelineMode: .calendarYear
    )
  )
}

#Preview("Daily Your 365 First Year") {
  previewWidget(
    HabitWidgetPreviewFixture(
      calendar: previewDailyCalendar(),
      timelineMode: .your365
    )
  )
}

#Preview("Daily Your 365 Small") {
  previewWidget(
    HabitWidgetPreviewFixture(
      calendar: previewDailyCalendar(),
      timelineMode: .your365,
      family: .systemSmall
    )
  )
}

#Preview("Daily Your 365 Mature") {
  previewWidget(
    HabitWidgetPreviewFixture(
      calendar: previewMatureCalendar(),
      timelineMode: .your365,
      referenceDate: previewDate(year: 2026, month: 2, day: 1),
      currentStreak: 186,
      isCurrentPeriodCompleted: true
    )
  )
}

#Preview("Weekly Unchanged") {
  previewWidget(
    HabitWidgetPreviewFixture(
      calendar: previewWeeklyCalendar(),
      timelineMode: .your365
    )
  )
}

private struct HabitWidgetPreviewFixture {
  let calendar: CustomCalendar
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let currentStreak: Int
  let todayCount: Int
  let isCurrentPeriodCompleted: Bool
  let family: WidgetFamily

  init(
    calendar: CustomCalendar,
    timelineMode: CalendarTimelineMode,
    referenceDate: Date = previewDate(year: 2026, month: 1, day: 11),
    currentStreak: Int = 7,
    todayCount: Int = 1,
    isCurrentPeriodCompleted: Bool = false,
    family: WidgetFamily = .systemLarge
  ) {
    self.calendar = calendar
    self.timelineMode = timelineMode
    self.referenceDate = referenceDate
    self.currentStreak = currentStreak
    self.todayCount = todayCount
    self.isCurrentPeriodCompleted = isCurrentPeriodCompleted
    self.family = family
  }
}

private func previewWidget(_ fixture: HabitWidgetPreviewFixture) -> some View {
  let renderingMode = WidgetStyle.RenderingMode.fullColor
  let backgroundColor = WidgetStyle.widgetBackgroundColor(for: .light, renderingMode: renderingMode)
  let primaryTextColor = WidgetStyle.primaryTextColor(for: .light, renderingMode: renderingMode)

  return HorizontalCalendarGrid(
    family: fixture.family,
    calendar: fixture.calendar,
    timelineMode: fixture.timelineMode,
    referenceDate: fixture.referenceDate,
    currentStreak: fixture.currentStreak,
    todayCount: fixture.todayCount,
    isCurrentPeriodCompleted: fixture.isCurrentPeriodCompleted,
    backgroundColor: backgroundColor,
    textPrimaryColor: primaryTextColor,
    inactiveRatio: WidgetStyle.futureDotFillRatio,
    renderingMode: renderingMode
  )
  .frame(width: 360, height: 260)
  .padding()
  .background(backgroundColor)
}

private func previewDailyCalendar() -> CustomCalendar {
  CustomCalendar(
    name: "Daily Habit",
    color: "qs-blue",
    cadence: .daily,
    trackingType: .counter,
    trackingStartedAt: previewDate(year: 2026, month: 1, day: 1),
    dailyTarget: 3,
    entries: previewEntries()
  )
}

private func previewMatureCalendar() -> CustomCalendar {
  CustomCalendar(
    name: "Mature Habit",
    color: "qs-green",
    cadence: .daily,
    trackingType: .multipleDaily,
    trackingStartedAt: previewDate(year: 2024, month: 1, day: 1),
    dailyTarget: 3,
    entries: previewEntries()
  )
}

private func previewWeeklyCalendar() -> CustomCalendar {
  CustomCalendar(
    name: "Weekly Habit",
    color: "qs-orange",
    cadence: .weekly,
    trackingType: .binary,
    trackingStartedAt: previewDate(year: 2026, month: 1, day: 1),
    dailyTarget: 1,
    entries: previewWeeklyEntries()
  )
}

private func previewEntries() -> [String: CalendarEntry] {
  Dictionary(uniqueKeysWithValues: [
    previewEntry(year: 2026, month: 1, day: 1, count: 2, completed: true),
    previewEntry(year: 2026, month: 1, day: 2, count: 1, completed: false),
    previewEntry(year: 2026, month: 1, day: 3, count: 3, completed: true)
  ])
}

private func previewWeeklyEntries() -> [String: CalendarEntry] {
  Dictionary(uniqueKeysWithValues: [
    previewEntry(year: 2026, month: 1, day: 5, count: 1, completed: true)
  ])
}

private func previewEntry(
  year: Int,
  month: Int,
  day: Int,
  count: Int,
  completed: Bool
) -> (String, CalendarEntry) {
  let date = previewDate(year: year, month: month, day: day)
  return (
    DayKeyFormatter.shared.string(from: date),
    CalendarEntry(
      date: date,
      count: count,
      completed: completed
    )
  )
}

private func previewDate(year: Int, month: Int, day: Int) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}
