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
    self.dotSize = 8.5
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
          return blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
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
        if family == .systemLarge || family == .systemMedium {
          if let calendar = calendar {
            Text(calendar.name)
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(textPrimaryColor)
              .fontWeight(.black)
          }
        }

        Spacer()

        if let calendar = calendar {
          let activeDays = calendar.entries.values.filter { entry in
            switch calendar.trackingType {
            case .binary:
              return entry.completed
            case .counter, .multipleDaily:
              return entry.count >= calendar.dailyTarget
            }
          }.count

          HStack(spacing: 4) {
            let today = Date()
            let formattedToday = customDateFormatter(date: today)

            if calendar.trackingType != .binary && family != .systemSmall {
              if let todayEntry = calendar.entries[formattedToday] {
                TodaysCountView(count: todayEntry.count)
              } else {
                TodaysCountView(count: 0)
              }
            }

            NumberOfDaysView(numberOfDays: activeDays)

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
        .padding(.top, 6)
        .padding(.bottom, 10)
        .padding(.horizontal, -16)

      GeometryReader { geometry in
        let padding: CGFloat = 0
        let availableWidth = max(1, geometry.size.width - (padding * 2))
        let availableHeight = max(1, geometry.size.height - (padding * 2))
        let aspectRatio = max(0.001, availableWidth / availableHeight)
        let dates = datesForFamily(today: today)
        let totalDays = dates.count
        let columns = adjustedColumns(for: totalDays, aspectRatio: aspectRatio)
        let rows = max(1, Int(ceil(Double(totalDays) / Double(columns))))
        let horizontalSpacing =
          (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(2, columns - 1))
        let verticalSpacing =
          (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(2, rows - 1))

        VStack(spacing: verticalSpacing) {
          ForEach(0..<rows, id: \.self) { row in
            HStack(spacing: horizontalSpacing) {
              ForEach(0..<columns, id: \.self) { col in
                let day = row * columns + col
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
    .background(Color.clear)
  }

  private func datesForFamily(today: Date) -> [Date] {
    switch family {
    case .systemSmall:
      return recentDates(from: today, days: 30)
    case .systemMedium:
      return recentMonths(from: today, months: 3)
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
    self.label = numberOfDays == 1 ? "day" : "days"
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
  }
}

struct TodaysCountView: View {
  let count: Int
  let label: String

  init(count: Int) {
    self.count = count
    self.label = count == 1 ? "time today" : "times today"
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
  }
}

struct WidgetGridDot: View {
  let color: Color
  let dotSize: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(color)
      .frame(width: dotSize, height: dotSize)
  }
}

struct WidgetSeparator: View {
  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color("devider-top"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
      Rectangle()
        .fill(Color("devider-bottom"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
  }
}

private func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
  let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
  var columns = max(1, min(targetColumns, count))
  while columns > 1 && count % columns == 1 {
    columns -= 1
  }
  return columns
}

private func makeLocalCalendar() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  return calendar
}

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  blendedColor(base: base, overlay: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
  blendedColor(base: base, overlay: overlay, ratio: 0.12)
}

private func blendedColor(base: Color, overlay: Color, ratio: Double) -> Color {
  let clampedRatio = max(0, min(1, ratio))
  let baseColor = UIColor(base)
  let overlayColor = UIColor(overlay)
  var baseRed: CGFloat = 0
  var baseGreen: CGFloat = 0
  var baseBlue: CGFloat = 0
  var baseAlpha: CGFloat = 0
  var overlayRed: CGFloat = 0
  var overlayGreen: CGFloat = 0
  var overlayBlue: CGFloat = 0
  var overlayAlpha: CGFloat = 0

  guard baseColor.getRed(&baseRed, green: &baseGreen, blue: &baseBlue, alpha: &baseAlpha),
    overlayColor.getRed(&overlayRed, green: &overlayGreen, blue: &overlayBlue, alpha: &overlayAlpha)
  else {
    return base
  }

  let red = baseRed + (overlayRed - baseRed) * clampedRatio
  let green = baseGreen + (overlayGreen - baseGreen) * clampedRatio
  let blue = baseBlue + (overlayBlue - baseBlue) * clampedRatio
  let alpha = baseAlpha + (overlayAlpha - baseAlpha) * clampedRatio

  return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
}

private func surfaceMutedColor(for colorScheme: ColorScheme) -> Color {
  switch colorScheme {
  case .dark:
    return Color(red: 0x18 / 255.0, green: 0x18 / 255.0, blue: 0x1B / 255.0)
  default:
    return Color(red: 0xE4 / 255.0, green: 0xE4 / 255.0, blue: 0xE7 / 255.0)
  }
}

private func textPrimaryColor(for colorScheme: ColorScheme) -> Color {
  switch colorScheme {
  case .dark:
    return Color(red: 0xFA / 255.0, green: 0xFA / 255.0, blue: 0xFA / 255.0)
  default:
    return Color(red: 0x09 / 255.0, green: 0x09 / 255.0, blue: 0x0B / 255.0)
  }
}

struct HabitsWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let destinationURL = entry.calendar.map { calendar in
      URL(string: "my-year://calendar/\(calendar.id.uuidString)")
    } ?? nil
    let backgroundColor = surfaceMutedColor(for: colorScheme)
    let primaryTextColor = textPrimaryColor(for: colorScheme)
    let inactiveRatio = colorScheme == .dark ? 0.08 : 0.06

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
