//
//  HabitsWidget.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import AppIntents
import SharedModels
import SwiftUI
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

struct HabitsWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var widgetRenderingMode

  var body: some View {
    let destinationURL = entry.calendar.flatMap { calendar in
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
