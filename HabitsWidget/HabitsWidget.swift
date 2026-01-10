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
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      configuration: ConfigurationAppIntent.defaultCalendar,
      calendar: resolvedCalendar(for: ConfigurationAppIntent.defaultCalendar)
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(
      date: Date(),
      configuration: configuration,
      calendar: resolvedCalendar(for: configuration)
    )
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    // Create a single entry with current data
    let entry = SimpleEntry(
      date: Date(),
      configuration: configuration,
      calendar: resolvedCalendar(for: configuration)
    )

    // Update at midnight
    let calendar: Calendar = Calendar.current
    let refreshDate: Date = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())

    return Timeline(entries: [entry], policy: .after(refreshDate))
  }

  private func resolvedCalendar(for configuration: ConfigurationAppIntent) -> CustomCalendar? {
    let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
    if let selectedId = configuration.selectedCalendar?.id {
      return calendars.first(where: { $0.id.uuidString == selectedId }) ?? calendars.first
    }
    return calendars.first
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let calendar: CustomCalendar?
}

struct HorizontalCalendarGrid: View {
  let dotSize: CGFloat
  let family: WidgetFamily
  let store = ValuationStore.shared
  let calendar: CustomCalendar?
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  private let calendarStore = CustomCalendarStore.shared
  private let localCalendar = makeLocalCalendar()


  init(
    family: WidgetFamily,
    calendar: CustomCalendar?,
    backgroundColor: Color,
    textPrimaryColor: Color,
    inactiveRatio: Double
  ) {
    self.family = family
    self.calendar = calendar
    self.backgroundColor = backgroundColor
    self.textPrimaryColor = textPrimaryColor
    self.inactiveRatio = inactiveRatio
    switch family {
    case .systemLarge:
      self.dotSize = 10.0
    case .systemMedium:
      self.dotSize = 7
    default:
      self.dotSize = 10.0
    }
  }


  private func colorForDay(_ date: Date, today: Date) -> Color {
    let normalized = localCalendar.startOfDay(for: date)
    let normalizedToday = localCalendar.startOfDay(for: today)

    if normalized > normalizedToday {
      return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    }

    let key = customDateFormatter(date: normalized)

    if let calendar = calendar,
      let entry = calendar.entries[key]
    {
      switch calendar.trackingType {
      case .binary:
        return entry.completed
          ? Color(calendar.color)
          : activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
      case .counter:
        let maxCount = max(1, calendar.entries.values.map { $0.count }.max() ?? 1)
        if entry.count > 0 {
          let ratio = max(0.1, Double(entry.count) / Double(maxCount))
          return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
        }
        return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
      case .multipleDaily:
        if entry.count > 0 {
          let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
          return Color(calendar.color).opacity(opacity)
        }
        return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
      }
    }

    return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
  }

  var body: some View {
    let today = Date()
    VStack {
      HStack(spacing: 6) {

        if let calendar = calendar {
          Text(calendar.name)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }


        Spacer()

        if let calendar = calendar {
          let currentStreak = currentStreak(for: calendar)

          HStack(spacing: 8) {
            let today = Date()
            let formattedToday = customDateFormatter(date: today)

            if calendar.trackingType != .binary && family != .systemSmall {
              if let todayEntry = calendar.entries[formattedToday] {
                TodaysCountView(count: todayEntry.count)
              } else {
                TodaysCountView(count: 0)
              }
            }

            if family != .systemSmall {
              if currentStreak > 0 {
                NumberOfDaysView(numberOfDays: currentStreak)
              }
            }

            if #available(iOS 17.0, *) {
              Button(intent: HabitQuickAddIntent(calendarId: calendar.id.uuidString)) {
                QuickAddButtonContent(
                  calendar: calendar, today: today)
              }
              .buttonStyle(.plain)
              .frame(width: 24, height: 24)
            } else {
              // Fallback for iOS 16 and earlier - will open the app
              Link(destination: URL(string: "my-year://quick-add/\(calendar.id.uuidString)")!) {
                QuickAddButtonContent(
                  calendar: calendar, today: today)
              }
              .frame(width: 24, height: 24)
            }
          }
        }
      }

      WidgetSeparator()
        .padding(.horizontal, -16)
        .padding(.bottom, 4)

      GeometryReader { geometry in
        let padding: CGFloat = 0
        let dates = datesForFamily(today: today)
        let totalDays = dates.count
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
                  WidgetGridDot(
                    color: colorForDay(dates[day], today: today),
                    dotSize: dotSize
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

  private func currentStreak(for calendar: CustomCalendar) -> Int {
    let today = localCalendar.startOfDay(for: Date())
    var streak = 0
    var cursor = today
    let todayKey = customDateFormatter(date: today)
    let todayEntry = calendar.entries[todayKey]
    let shouldSkipToday = todayEntry == nil || (todayEntry != nil && isEntryEmpty(todayEntry!))

    if shouldSkipToday {
      guard let previous = localCalendar.date(byAdding: .day, value: -1, to: today) else {
        return 0
      }
      cursor = previous
    }

    while true {
      let key = customDateFormatter(date: cursor)
      guard let entry = calendar.entries[key], isEntrySuccess(entry, calendar: calendar) else {
        break
      }
      streak += 1

      guard let previous = localCalendar.date(byAdding: .day, value: -1, to: cursor) else {
        break
      }
      cursor = previous
    }

    return streak
  }

  private func hasEntry(on date: Date, calendar: CustomCalendar) -> Bool {
    let key = customDateFormatter(date: date)
    return calendar.entries[key] != nil
  }

  private func isEntryEmpty(_ entry: CalendarEntry) -> Bool {
    return entry.count == 0 && entry.completed == false
  }

  private func isEntrySuccess(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter:
      return entry.count > 0
    case .multipleDaily:
      return entry.count >= calendar.dailyTarget
    }
  }

  private func datesForFamily(today: Date) -> [Date] {
    switch family {
    case .systemSmall:
      return recentDates(from: today, days: 35)
    case .systemMedium:
      // return recentMonths(from: today, months: 6)
      return (0..<store.numberOfDaysInYear).map { store.dateForDay($0) }
    default:
      return (0..<store.numberOfDaysInYear).map { store.dateForDay($0) }
    }
  }

  private func recentDates(from today: Date, days: Int) -> [Date] {
    let end = localCalendar.startOfDay(for: today)
    guard let start = localCalendar.date(byAdding: .day, value: -(days - 1), to: end) else {
      return [end]
    }
    return buildDates(from: start, to: end)
  }

  private func recentMonths(from today: Date, months: Int) -> [Date] {
    let end = localCalendar.startOfDay(for: today)
    guard let start = localCalendar.date(byAdding: .month, value: -months, to: end) else {
      return [end]
    }
    return buildDates(from: start, to: end)
  }

  private func buildDates(from start: Date, to end: Date) -> [Date] {
    var dates: [Date] = []
    var current = start
    while current <= end {
      dates.append(current)
      guard let next = localCalendar.date(byAdding: .day, value: 1, to: current) else {
        break
      }
      current = next
    }
    return dates
  }
}

struct QuickAddButtonContent: View {
  let calendar: CustomCalendar
  let today: Date
  let calendarStore = CustomCalendarStore.shared

  var body: some View {
    let isCompleted = calendarStore.getEntry(calendarId: calendar.id, date: today)?.completed == true
    ZStack {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color(calendar.color).opacity(0.1))
        .frame(width: 24, height: 24)

      Image(
        systemName: calendar.trackingType == .binary
          && isCompleted
          ? "minus" : "plus"
      )
      .font(.system(size: 16))
      .foregroundColor(Color(calendar.color))
    }

  }
}

struct NumberOfDaysView: View {
  let numberOfDays: Int
  let label: String

  init(numberOfDays: Int) {
    self.numberOfDays = numberOfDays
    self.label = numberOfDays == 1 ? "day" : "days streak"
  }

  var body: some View {
    HStack {
      Text("\(numberOfDays)")
        .fontWeight(.bold)
        + Text(" \(label)")
        .foregroundColor(Color("text-tertiary"))
    }
    .foregroundColor(Color("text-primary"))
    .font(.system(size: 9, design: .monospaced))
    .contentTransition(.numericText())
  }
}

struct TodaysCountView: View {
  let count: Int
  let label: String

  init(count: Int) {
    self.count = count
    self.label = "today"
  }

  var body: some View {
    HStack {
      Text("\(count)")
        .fontWeight(.bold)
        + Text(" \(label)")
        .foregroundColor(Color("text-tertiary"))
    }
    .lineLimit(1)
    .foregroundColor(Color("text-primary"))
    .font(.system(size: 9, design: .monospaced))
    .contentTransition(.numericText())
  }
}

private func makeLocalCalendar() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  return calendar
}

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  WidgetStyle.inactiveDotColor(surface: base, text: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
  WidgetStyle.activeDotColor(surface: base, text: overlay, ratio: 0.12)
}

struct HabitsWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let destinationURL = entry.calendar.map { calendar in
      URL(string: "my-year://calendar/\(calendar.id.uuidString)")
    } ?? nil
    let backgroundColor = WidgetStyle.surfaceMutedColor(for: colorScheme)
    let primaryTextColor = WidgetStyle.textPrimaryColor(for: colorScheme)
    let inactiveRatio = 0.04

    if #available(iOS 17.0, *) {
      HorizontalCalendarGrid(
        family: family,
        calendar: entry.calendar,
        backgroundColor: backgroundColor,
        textPrimaryColor: primaryTextColor,
        inactiveRatio: inactiveRatio
      )
        .containerBackground(backgroundColor, for: .widget)
        .widgetURL(destinationURL)
    } else {
      HorizontalCalendarGrid(
        family: family,
        calendar: entry.calendar,
        backgroundColor: backgroundColor,
        textPrimaryColor: primaryTextColor,
        inactiveRatio: inactiveRatio
      )
        .padding()
        .background(backgroundColor)
        .widgetURL(destinationURL)
    }
  }
}

struct HabitsWidget: Widget {
  let kind: String = "HabitsWidget"

  var body: some WidgetConfiguration {
    let configuration = AppIntentConfiguration(
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

    return configuration
  }
}

struct HabitQuickAddIntent: AppIntent, SetValueIntent {
  static var title: LocalizedStringResource = "Quick Add Habit Entry"
  static var description = IntentDescription("Quickly add an entry to your habit tracker")

  @Parameter(title: "Calendar ID")
  var calendarId: String

  @Parameter(title: "Value")
  var value: Bool  // Required by SetValueIntent

  init() {
    self.calendarId = ""
    self.value = false
  }

  init(calendarId: String) {
    self.calendarId = calendarId
    self.value = false
  }

  func perform() async throws -> some IntentResult {
    let store = CustomCalendarStore.shared

    let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
    guard let calendar = calendars.first(where: { $0.id.uuidString == calendarId }) else {
      return .result()
    }

    let today: Date = Date()
    var newEntry: CalendarEntry
    let addValue = calendar.defaultRecordValue ?? 1

    if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
      if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
        newEntry = CalendarEntry(
          date: today,
          count: existingEntry.count + addValue,
          completed: calendar.trackingType == .counter
            ? existingEntry.count + addValue > 0
            : existingEntry.count + addValue >= calendar.dailyTarget
        )
      } else {
        newEntry = CalendarEntry(
          date: today,
          count: 1,
          completed: !existingEntry.completed
        )
      }
    } else {
      switch calendar.trackingType {
      case .counter:
        newEntry = CalendarEntry(date: today, count: 1, completed: true)
      case .multipleDaily:
        newEntry = CalendarEntry(date: today, count: 1, completed: false)
      case .binary:
        newEntry = CalendarEntry(date: today, count: 1, completed: true)
      }
    }

    do {
      try store.addEntry(calendarId: calendar.id, entry: newEntry)
      // Only reload the HabitsWidget
      WidgetCenter.shared.reloadTimelines(ofKind: "HabitsWidget")

      let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
      impactFeedbackgenerator.prepare()
      impactFeedbackgenerator.impactOccurred()
    } catch {
      return .result()
    }

    return .result()
  }
}
