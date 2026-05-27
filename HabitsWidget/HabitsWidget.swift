//
//  HabitsWidget.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import AppIntents
import SharedModels
import SwiftUI
import UIKit
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> SimpleEntry {
    makeEntry(for: ConfigurationAppIntent.defaultCalendar, date: Date())
  }

  func snapshot(for configuration: ConfigurationAppIntent, in _: Context) async -> SimpleEntry {
    makeEntry(for: configuration, date: Date())
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    let currentDate = Date()
    let entry = makeEntry(for: configuration, date: currentDate)

    if !context.isPreview {
      let analyticsTimelineMode = entry.calendar.map {
        entry.timelineMode.effectiveMode(for: $0.cadence)
      } ?? entry.timelineMode

      WidgetAnalyticsQueue.shared.enqueueTimelineLoaded(properties: [
        "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
        "widget_family": .string(widgetFamilyName(context.family)),
        "has_calendar": .bool(entry.calendar != nil),
        "cadence": .string(entry.calendar?.cadence.rawValue ?? "unknown"),
        "tracking_type": .string(entry.calendar?.trackingType.analyticsValue ?? "unknown"),
        "timeline_mode": .string(analyticsTimelineMode.rawValue)
      ])
    }

    // Update at midnight
    let calendar = Calendar.current
    let refreshDate: Date = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    )

    return Timeline(entries: [entry], policy: .after(refreshDate))
  }

  private func resolvedCalendar(for configuration: ConfigurationAppIntent) -> CustomCalendar? {
    let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
    if let selectedId = configuration.selectedCalendar?.id {
      return calendars.first(where: { $0.id.uuidString == selectedId })
    }
    return calendars.first
  }

  private func makeEntry(for configuration: ConfigurationAppIntent, date: Date) -> SimpleEntry {
    let calendar = resolvedCalendar(for: configuration)
    let streakData = calendar.map { WidgetStreak.currentStreak(calendar: $0) }
    let todayEntry = calendar?.entry(for: date)
    let timelineMode = TimelinePreferenceStore.mode()

    return SimpleEntry(
      date: date,
      configuration: configuration,
      calendar: calendar,
      timelineMode: timelineMode,
      currentStreak: streakData?.streak ?? 0,
      todayCount: todayEntry?.count ?? 0,
      isCurrentPeriodCompleted: todayEntry?.completed ?? false
    )
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let currentStreak: Int
  let todayCount: Int
  let isCurrentPeriodCompleted: Bool
}

struct HorizontalCalendarGrid: View {
  let dotSize: CGFloat
  let family: WidgetFamily
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let currentStreak: Int
  let todayCount: Int
  let isCurrentPeriodCompleted: Bool
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  let renderingMode: WidgetStyle.RenderingMode

  init(
    family: WidgetFamily,
    calendar: CustomCalendar?,
    timelineMode: CalendarTimelineMode,
    referenceDate: Date,
    currentStreak: Int,
    todayCount: Int,
    isCurrentPeriodCompleted: Bool,
    backgroundColor: Color,
    textPrimaryColor: Color,
    inactiveRatio: Double,
    renderingMode: WidgetStyle.RenderingMode
  ) {
    self.family = family
    self.calendar = calendar
    self.timelineMode = timelineMode
    self.referenceDate = referenceDate
    self.currentStreak = currentStreak
    self.todayCount = todayCount
    self.isCurrentPeriodCompleted = isCurrentPeriodCompleted
    self.backgroundColor = backgroundColor
    self.textPrimaryColor = textPrimaryColor
    self.inactiveRatio = inactiveRatio
    self.renderingMode = renderingMode
    switch family {
    case .systemLarge:
      dotSize = 10.0
    case .systemMedium:
      dotSize = 7
    default:
      dotSize = 10.0
    }
  }

  var body: some View {
    VStack {
      HStack(spacing: 6) {
        if let calendar = calendar {
          Text(calendar.name)
            .font(AppFont.mono(12))
            .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
            .fontWeight(.heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }

        Spacer()

        if let calendar = calendar {
          HStack(spacing: 8) {
            if calendar.trackingType != .binary && family != .systemSmall {
              TodaysCountView(count: todayCount, cadence: calendar.cadence, renderingMode: renderingMode)
            }

            if family != .systemSmall, currentStreak > 0 {
              NumberOfDaysView(numberOfDays: currentStreak, cadence: calendar.cadence, renderingMode: renderingMode)
            }

            if #available(iOS 17.0, *) {
              Button(intent: HabitQuickAddIntent(calendarId: calendar.id.uuidString)) {
                QuickAddButtonContent(
                  calendar: calendar,
                  isCurrentPeriodCompleted: isCurrentPeriodCompleted,
                  renderingMode: renderingMode
                )
              }
              .buttonStyle(.plain)
              .frame(width: 24, height: 24)
            } else {
              // Fallback for iOS 16 and earlier - will open the app
              Link(
                destination: widgetDeepLink(
                  host: "quick-add",
                  calendarId: calendar.id.uuidString,
                  widgetKind: WidgetAnalyticsKind.habits.rawValue,
                  widgetAction: "quick_add"
                )
              ) {
                QuickAddButtonContent(
                  calendar: calendar,
                  isCurrentPeriodCompleted: isCurrentPeriodCompleted,
                  renderingMode: renderingMode
                )
              }
              .frame(width: 24, height: 24)
            }
          }
        }
      }

      WidgetSeparator(renderingMode: renderingMode)
        .padding(.horizontal, -16)
        .padding(.bottom, 4)

      GeometryReader { geometry in
        let padding: CGFloat = 0
        let gridSnapshot = HabitWidgetGridSnapshot.make(
          family: family,
          calendar: calendar,
          timelineMode: timelineMode,
          referenceDate: referenceDate,
          backgroundColor: backgroundColor,
          textPrimaryColor: textPrimaryColor,
          inactiveRatio: inactiveRatio,
          renderingMode: renderingMode
        )
        let totalDays = gridSnapshot.days.count
        let availableWidth = geometry.size.width - (padding * 2)
        let availableHeight = geometry.size.height - (padding * 2)
        let layout = WidgetStyle.gridLayout(
          count: totalDays,
          dotSize: dotSize,
          availableWidth: availableWidth,
          availableHeight: availableHeight
        )

        VStack(spacing: layout.verticalSpacing) {
          ForEach(0..<layout.rows, id: \.self) { row in
            HStack(spacing: layout.horizontalSpacing) {
              ForEach(0..<layout.columns, id: \.self) { col in
                let day = row * layout.columns + col
                if day < totalDays {
                  let gridDay = gridSnapshot.days[day]
                  WidgetGridDot(
                    color: gridDay.color,
                    dotSize: dotSize,
                    accentable: gridDay.accentable
                  )
                } else {
                  Color.clear.frame(width: dotSize, height: dotSize)
                }
              }
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .padding()
    .background(backgroundColor)
  }

}

struct QuickAddButtonContent: View {
  let calendar: CustomCalendar
  let isCurrentPeriodCompleted: Bool
  let renderingMode: WidgetStyle.RenderingMode

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3)
        .fill(
          renderingMode.isMonochrome
            ? WidgetStyle.monochromeSecondaryColor().opacity(0.16) : Color(calendar.color).opacity(0.1)
        )
        .frame(width: 24, height: 24)

      Image(
        systemName: calendar.trackingType == .binary
          && isCurrentPeriodCompleted
          ? "minus" : "plus"
      )
      .font(.system(size: 16))
      .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color(calendar.color))
      .widgetAccentable(renderingMode.isMonochrome)
    }
    .widgetAccentable(false)
  }
}

struct NumberOfDaysView: View {
  let numberOfDays: Int
  let cadence: CalendarCadence
  let renderingMode: WidgetStyle.RenderingMode
  private let textParts: LocalizedStreakTextParts

  init(numberOfDays: Int, cadence: CalendarCadence, renderingMode: WidgetStyle.RenderingMode) {
    self.numberOfDays = numberOfDays
    self.cadence = cadence
    self.renderingMode = renderingMode
    if cadence == .weekly {
      let format =
        numberOfDays == 1
        ? String(localized: "habitWidget.weekStreak")
        : String(localized: "habitWidget.weeksStreak")
      textParts = LocalizedStreakTextParts(format: format, value: numberOfDays)
    } else {
      let format =
        numberOfDays == 1
        ? String(localized: "habitWidget.dayStreak")
        : String(localized: "habitWidget.daysStreak")
      textParts = LocalizedStreakTextParts(format: format, value: numberOfDays)
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      Text(textParts.prefix)
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary"))
        .widgetAccentable(false)

      Text(textParts.value)
        .fontWeight(.bold)
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary"))
        .widgetAccentable(renderingMode.isMonochrome)

      Text(textParts.suffix)
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary"))
        .widgetAccentable(false)
    }
    .lineLimit(1)
    .font(AppFont.mono(9))
    .contentTransition(.numericText())
  }
}

private struct LocalizedStreakTextParts {
  let prefix: String
  let value: String
  let suffix: String

  init(format: String, value: Int) {
    let components = format.components(separatedBy: "%lld")
    guard components.count == 2 else {
      assertionFailure("Streak localization must contain exactly one %lld placeholder.")
      prefix = ""
      self.value = value.formatted(.number.locale(.current))
      suffix = ""
      return
    }

    prefix = components[0]
    self.value = value.formatted(.number.locale(.current))
    suffix = components[1]
  }
}

struct TodaysCountView: View {
  let count: Int
  let cadence: CalendarCadence
  let renderingMode: WidgetStyle.RenderingMode
  let label: String

  init(count: Int, cadence: CalendarCadence, renderingMode: WidgetStyle.RenderingMode) {
    self.count = count
    self.cadence = cadence
    self.renderingMode = renderingMode
    label = cadence == .weekly ? String(localized: "this week") : String(localized: "today")
  }

  var body: some View {
    HStack {
      Text("\(count)")
        .fontWeight(.bold)
        .widgetAccentable(renderingMode.isMonochrome && count.hasLoggedValue)

      Text(" \(label)")
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary"))
    }
    .lineLimit(1)
    .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary"))
    .font(AppFont.mono(9))
    .contentTransition(.numericText())
  }
}

struct HabitsWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var widgetRenderingMode

  var body: some View {
    let destinationURL = entry.calendar.map { calendar in
      widgetDeepLink(
        host: "calendar",
        calendarId: calendar.id.uuidString,
        widgetKind: WidgetAnalyticsKind.habits.rawValue,
        widgetAction: "open_calendar"
      )
    }
    let renderingMode = WidgetStyle.RenderingMode(widgetRenderingMode)
    let backgroundColor = WidgetStyle.widgetBackgroundColor(for: colorScheme, renderingMode: renderingMode)
    let primaryTextColor = WidgetStyle.primaryTextColor(for: colorScheme, renderingMode: renderingMode)
    let inactiveRatio = WidgetStyle.futureDotFillRatio

    if #available(iOS 17.0, *) {
      HorizontalCalendarGrid(
        family: family,
        calendar: entry.calendar,
        timelineMode: entry.timelineMode,
        referenceDate: entry.date,
        currentStreak: entry.currentStreak,
        todayCount: entry.todayCount,
        isCurrentPeriodCompleted: entry.isCurrentPeriodCompleted,
        backgroundColor: backgroundColor,
        textPrimaryColor: primaryTextColor,
        inactiveRatio: inactiveRatio,
        renderingMode: renderingMode
      )
      .containerBackground(backgroundColor, for: .widget)
      .widgetURL(destinationURL)
    } else {
      HorizontalCalendarGrid(
        family: family,
        calendar: entry.calendar,
        timelineMode: entry.timelineMode,
        referenceDate: entry.date,
        currentStreak: entry.currentStreak,
        todayCount: entry.todayCount,
        isCurrentPeriodCompleted: entry.isCurrentPeriodCompleted,
        backgroundColor: backgroundColor,
        textPrimaryColor: primaryTextColor,
        inactiveRatio: inactiveRatio,
        renderingMode: renderingMode
      )
      .widgetURL(destinationURL)
    }
  }
}

struct HabitsWidget: Widget {
  let kind: String = WidgetKinds.habits

  var body: some WidgetConfiguration {
    return AppIntentConfiguration(
      kind: kind,
      intent: ConfigurationAppIntent.self,
      provider: Provider()
    ) { entry in
      HabitsWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Habit Progress")
    .description("Track your habit's progress with a beautiful visualization.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

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
      WidgetAnalyticsQueue.shared.enqueueQuickAddPerformed(properties: [
        "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
        "cadence": .string("unknown"),
        "tracking_type": .string("unknown"),
        "result": .string("invalid_calendar")
      ])
      return .result()
    }

    let calendar = await MainActor.run {
      CustomCalendarStore.fetchCalendarsSnapshot().first(where: { $0.id == calendarId })
    }

    guard let calendar else {
      WidgetAnalyticsQueue.shared.enqueueQuickAddPerformed(properties: [
        "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
        "cadence": .string("unknown"),
        "tracking_type": .string("unknown"),
        "result": .string("invalid_calendar")
      ])
      return .result()
    }

    let quickLogSucceeded = await MainActor.run {
      let didSave = store.quickLogEntry(calendarId: calendarId, date: Date())
      let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
      impactFeedbackgenerator.prepare()
      impactFeedbackgenerator.impactOccurred()
      return didSave
    }

    guard quickLogSucceeded else {
      WidgetAnalyticsQueue.shared.enqueueQuickAddPerformed(properties: [
        "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
        "cadence": .string(calendar.cadence.rawValue),
        "tracking_type": .string(calendar.trackingType.analyticsValue),
        "result": .string("failed")
      ])
      return .result()
    }

    WidgetAnalyticsQueue.shared.enqueueQuickAddPerformed(properties: [
      "widget_kind": .string(WidgetAnalyticsKind.habits.rawValue),
      "cadence": .string(calendar.cadence.rawValue),
      "tracking_type": .string(calendar.trackingType.analyticsValue),
      "result": .string("success")
    ])

    return .result()
  }
}

private func widgetFamilyName(_ family: WidgetFamily) -> String {
  switch family {
  case .systemSmall: return WidgetAnalyticsFamily.systemSmall.rawValue
  case .systemMedium: return WidgetAnalyticsFamily.systemMedium.rawValue
  case .systemLarge: return WidgetAnalyticsFamily.systemLarge.rawValue
  default: return WidgetAnalyticsFamily.other.rawValue
  }
}

private func widgetDeepLink(
  host: String,
  calendarId: String?,
  widgetKind: String,
  widgetAction: String
) -> URL {
  var components = URLComponents()
  components.scheme = "my-year"
  components.host = host
  components.queryItems = [
    URLQueryItem(name: "source", value: "widget"),
    URLQueryItem(name: "widget_kind", value: widgetKind),
    URLQueryItem(name: "widget_action", value: widgetAction)
  ]

  if let calendarId {
    components.path = "/\(calendarId)"
  }

  return components.url ?? URL(string: "my-year://")!
}

#Preview("Daily Calendar Year") {
  previewWidget(
    calendar: previewDailyCalendar(),
    timelineMode: .calendarYear,
    referenceDate: previewDate(year: 2026, month: 1, day: 11),
    currentStreak: 7,
    todayCount: 1,
    isCurrentPeriodCompleted: false,
    family: .systemLarge
  )
}

#Preview("Daily Your 365 First Year") {
  previewWidget(
    calendar: previewDailyCalendar(),
    timelineMode: .your365,
    referenceDate: previewDate(year: 2026, month: 1, day: 11),
    currentStreak: 7,
    todayCount: 1,
    isCurrentPeriodCompleted: false,
    family: .systemLarge
  )
}

#Preview("Daily Your 365 Small") {
  previewWidget(
    calendar: previewDailyCalendar(),
    timelineMode: .your365,
    referenceDate: previewDate(year: 2026, month: 1, day: 11),
    currentStreak: 7,
    todayCount: 1,
    isCurrentPeriodCompleted: false,
    family: .systemSmall
  )
}

#Preview("Daily Your 365 Mature") {
  previewWidget(
    calendar: previewMatureCalendar(),
    timelineMode: .your365,
    referenceDate: previewDate(year: 2026, month: 2, day: 1),
    currentStreak: 186,
    todayCount: 1,
    isCurrentPeriodCompleted: true,
    family: .systemLarge
  )
}

#Preview("Weekly Unchanged") {
  previewWidget(
    calendar: previewWeeklyCalendar(),
    timelineMode: .your365,
    referenceDate: previewDate(year: 2026, month: 1, day: 11),
    currentStreak: 7,
    todayCount: 1,
    isCurrentPeriodCompleted: false,
    family: .systemLarge
  )
}

private func previewWidget(
  calendar: CustomCalendar,
  timelineMode: CalendarTimelineMode,
  referenceDate: Date,
  currentStreak: Int,
  todayCount: Int,
  isCurrentPeriodCompleted: Bool,
  family: WidgetFamily
) -> some View {
  let renderingMode = WidgetStyle.RenderingMode.fullColor
  let backgroundColor = WidgetStyle.widgetBackgroundColor(for: .light, renderingMode: renderingMode)
  let primaryTextColor = WidgetStyle.primaryTextColor(for: .light, renderingMode: renderingMode)

  return HorizontalCalendarGrid(
    family: family,
    calendar: calendar,
    timelineMode: timelineMode,
    referenceDate: referenceDate,
    currentStreak: currentStreak,
    todayCount: todayCount,
    isCurrentPeriodCompleted: isCurrentPeriodCompleted,
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

private func previewEntry(year: Int, month: Int, day: Int, count: Int, completed: Bool) -> (String, CalendarEntry) {
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
