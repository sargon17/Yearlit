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
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationAppIntent.defaultCalendar)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(date: Date(), configuration: configuration)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    // Create a single entry with current data
    let entry = SimpleEntry(date: Date(), configuration: configuration)

    // Update at midnight
    let calendar: Calendar = Calendar.current
    let refreshDate: Date = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())

    return Timeline(entries: [entry], policy: .after(refreshDate))
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
}

struct HorizontalCalendarGrid: View {
  let dotSize: CGFloat
  let family: WidgetFamily
  let store = ValuationStore.shared
  let calendar: CustomCalendar?
  private let calendarStore = CustomCalendarStore.shared

  init(family: WidgetFamily, calendar: CustomCalendar?) {
    self.family = family
    self.calendar = calendar
    switch family {
    case .systemLarge:
      self.dotSize = 10.0
    case .systemMedium:
      self.dotSize = 7.0
    default:
      self.dotSize = 4.0
    }
  }

  private func colorForDay(_ day: Int) -> Color {
    let dayDate = store.dateForDay(day)

    if day >= store.currentDayNumber {
      return Color("dot-inactive")
    }

    let key = customDateFormatter(date: dayDate)

    if let calendar = calendar,
      let entry = calendar.entries[key]
    {
      switch calendar.trackingType {
      case .binary:
        return entry.completed ? Color(calendar.color) : Color("dot-active")
      case .counter, .multipleDaily:
        let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
        let opacity = max(0.2, Double(entry.count) / Double(maxCount))
        return Color(calendar.color).opacity(opacity)
      }
    }

    return Color("dot-active")
  }

  var body: some View {
    VStack {
      HStack(spacing: 6) {
        if family == .systemLarge || family == .systemMedium {
          if let calendar = calendar {
            Text(calendar.name)
              .font(.system(size: 12))
              .foregroundColor(Color("text-primary"))
              .fontWeight(.bold)
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

            if calendar.trackingType != .binary || family != .systemSmall {
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

      GeometryReader { geometry in
        let aspectRatio = geometry.size.height / geometry.size.width
        let targetRows = Int(sqrt(Double(365) * aspectRatio))
        let rows = min(targetRows, 365)
        let columns = Int(ceil(Double(365) / Double(rows)))

        // Calculate a single spacing value that works for both directions
        let horizontalTotalSpace = geometry.size.width - (dotSize * CGFloat(columns))
        let verticalTotalSpace = geometry.size.height - (dotSize * CGFloat(rows))
        let spacing = min(
          horizontalTotalSpace / CGFloat(columns - 1),
          verticalTotalSpace / CGFloat(rows - 1)
        )

        HStack(spacing: spacing) {
          ForEach(0..<columns, id: \.self) { column in
            VStack(spacing: spacing) {
              ForEach(0..<rows, id: \.self) { row in
                let day = column * rows + row
                if day < store.numberOfDaysInYear {
                  RoundedRectangle(cornerRadius: 1)
                    .fill(colorForDay(day))
                    .frame(width: dotSize, height: dotSize)
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
}

struct QuickAddButtonContent: View {
  let calendar: CustomCalendar
  let today: Date
  let calendarStore = CustomCalendarStore.shared

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 4)
        .fill(Color(calendar.color).opacity(0.1))
        .frame(width: 24, height: 24)

      Image(
        systemName: calendar.trackingType == .binary
          && calendarStore.getEntry(calendarId: calendar.id, date: today) != nil
          && calendarStore.getEntry(calendarId: calendar.id, date: today)!.completed
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
    .font(.system(size: 9))
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
    .font(.system(size: 9))
  }
}

struct HabitsWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  private let store = CustomCalendarStore.shared

  var selectedCalendar: CustomCalendar? {
    return store.calendars.first { calendar in
      calendar.id.uuidString == entry.configuration.selectedCalendar?.id
    }
  }

  var body: some View {
    if #available(iOS 17.0, *) {
      HorizontalCalendarGrid(family: family, calendar: selectedCalendar)
        .containerBackground(Color("surface-muted"), for: .widget)
    } else {
      HorizontalCalendarGrid(family: family, calendar: selectedCalendar)
        .padding()
        .background(Color("surface-muted"))
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
    let valStore = ValuationStore.shared

    guard let calendar = store.calendars.first(where: { $0.id.uuidString == calendarId }) else {
      return .result()
    }

    let today: Date = Date()
    var newEntry: CalendarEntry

    if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
      if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
        newEntry = CalendarEntry(
          date: today,
          count: existingEntry.count + 1,
          completed: false
        )
      } else {
        newEntry = CalendarEntry(
          date: today,
          count: 1,
          completed: !existingEntry.completed
        )
      }
    } else {
      // Handle case when there's no existing entry
      newEntry = CalendarEntry(
        date: today,
        count: 1,
        completed: calendar.trackingType == .binary  // true for binary, false for others
      )
    }

    do {
      try store.addEntry(calendarId: calendar.id, entry: newEntry)
      // Only reload the HabitsWidget
      WidgetCenter.shared.reloadTimelines(ofKind: "HabitsWidget")
    } catch {
      print("Error adding entry: \(error) \(newEntry)")
      return .result()
    }

    return .result()
  }
}
