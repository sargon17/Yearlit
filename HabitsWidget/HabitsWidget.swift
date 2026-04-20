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

    func timeline(for configuration: ConfigurationAppIntent, in _: Context) async -> Timeline<
        SimpleEntry
    > {
        let currentDate = Date()
        let entry = makeEntry(for: configuration, date: currentDate)

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

        return SimpleEntry(
            date: date,
            configuration: configuration,
            calendar: calendar,
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
    let currentStreak: Int
    let todayCount: Int
    let isCurrentPeriodCompleted: Bool
}

struct HorizontalCalendarGrid: View {
    let dotSize: CGFloat
    let family: WidgetFamily
    let calendar: CustomCalendar?
    let referenceDate: Date
    let currentStreak: Int
    let todayCount: Int
    let isCurrentPeriodCompleted: Bool
    let backgroundColor: Color
    let textPrimaryColor: Color
    let inactiveRatio: Double
    private let localCalendar = makeLocalCalendar()

    init(
        family: WidgetFamily,
        calendar: CustomCalendar?,
        referenceDate: Date,
        currentStreak: Int,
        todayCount: Int,
        isCurrentPeriodCompleted: Bool,
        backgroundColor: Color,
        textPrimaryColor: Color,
        inactiveRatio: Double
    ) {
        self.family = family
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.currentStreak = currentStreak
        self.todayCount = todayCount
        self.isCurrentPeriodCompleted = isCurrentPeriodCompleted
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.inactiveRatio = inactiveRatio
        switch family {
        case .systemLarge:
            dotSize = 10.0
        case .systemMedium:
            dotSize = 7
        default:
            dotSize = 10.0
        }
    }

    private func colorForDay(_ date: Date, today: Date) -> Color {
        let normalized = localCalendar.startOfDay(for: date)
        let normalizedToday = localCalendar.startOfDay(for: today)

        if normalized > normalizedToday {
            return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
        }

        if let calendar = calendar,
           let entry = calendar.entry(for: normalized)
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
                    HStack(spacing: 8) {
                        if calendar.trackingType != .binary && family != .systemSmall {
                            TodaysCountView(count: todayCount, cadence: calendar.cadence)
                        }

                        if family != .systemSmall, currentStreak > 0 {
                            NumberOfDaysView(numberOfDays: currentStreak, cadence: calendar.cadence)
                        }

                        if #available(iOS 17.0, *) {
                            Button(intent: HabitQuickAddIntent(calendarId: calendar.id.uuidString)) {
                                QuickAddButtonContent(
                                    calendar: calendar,
                                    isCurrentPeriodCompleted: isCurrentPeriodCompleted
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24, height: 24)
                        } else {
                            // Fallback for iOS 16 and earlier - will open the app
                            Link(destination: URL(string: "my-year://quick-add/\(calendar.id.uuidString)")!) {
                                QuickAddButtonContent(
                                    calendar: calendar,
                                    isCurrentPeriodCompleted: isCurrentPeriodCompleted
                                )
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
                let dates = datesForFamily(today: referenceDate)
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
                    ForEach(0 ..< layout.rows, id: \.self) { row in
                        HStack(spacing: layout.horizontalSpacing) {
                            ForEach(0 ..< layout.columns, id: \.self) { col in
                                let day = row * layout.columns + col
                                if day < totalDays {
                                    WidgetGridDot(
                                        color: colorForDay(dates[day], today: referenceDate),
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

    private func datesForFamily(today: Date) -> [Date] {
        if let calendar, calendar.cadence == .weekly {
            switch family {
            case .systemSmall:
                return recentWeeks(from: today, weeks: 35)
            case .systemMedium, .systemLarge:
                return yearWeeks(containing: today)
            default:
                return yearWeeks(containing: today)
            }
        }

        switch family {
        case .systemSmall:
            return recentDates(from: today, days: 35)
        case .systemMedium:
            return yearDates(containing: today)
        default:
            return yearDates(containing: today)
        }
    }

    private func yearDates(containing date: Date) -> [Date] {
        let year = localCalendar.component(.year, from: date)
        guard let start = localCalendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = localCalendar.date(from: DateComponents(year: year, month: 12, day: 31))
        else {
            return []
        }

        return buildDates(from: start, to: end)
    }

    private func recentDates(from today: Date, days: Int) -> [Date] {
        let end = localCalendar.startOfDay(for: today)
        guard let start = localCalendar.date(byAdding: .day, value: -(days - 1), to: end) else {
            return [end]
        }
        return buildDates(from: start, to: end)
    }

    private func recentWeeks(from today: Date, weeks: Int) -> [Date] {
        let end = LocalDayCalendar.startOfWeek(for: today)
        guard let start = localCalendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: end) else {
            return [end]
        }
        return buildWeekDates(from: start, to: end)
    }

    private func yearWeeks(containing date: Date) -> [Date] {
        let year = localCalendar.component(.year, from: date)
        guard let start = localCalendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = localCalendar.date(from: DateComponents(year: year, month: 12, day: 31))
        else {
            return []
        }

        return buildWeekDates(from: LocalDayCalendar.startOfWeek(for: start), to: LocalDayCalendar.startOfWeek(for: end))
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

    private func buildWeekDates(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = LocalDayCalendar.startOfWeek(for: start)
        let last = LocalDayCalendar.startOfWeek(for: end)

        while current <= last {
            dates.append(current)
            guard let next = localCalendar.date(byAdding: .weekOfYear, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}

struct QuickAddButtonContent: View {
    let calendar: CustomCalendar
    let isCurrentPeriodCompleted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(calendar.color).opacity(0.1))
                .frame(width: 24, height: 24)

            Image(
                systemName: calendar.trackingType == .binary
                    && isCurrentPeriodCompleted
                    ? "minus" : "plus"
            )
            .font(.system(size: 16))
            .foregroundColor(Color(calendar.color))
        }
    }
}

struct NumberOfDaysView: View {
    let numberOfDays: Int
    let cadence: CalendarCadence
    let label: String

    init(numberOfDays: Int, cadence: CalendarCadence) {
        self.numberOfDays = numberOfDays
        self.cadence = cadence
        if cadence == .weekly {
            label = numberOfDays == 1 ? String(localized: "week") : String(localized: "weeks streak")
        } else {
            label = numberOfDays == 1 ? String(localized: "day") : String(localized: "days streak")
        }
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
    let cadence: CalendarCadence
    let label: String

    init(count: Int, cadence: CalendarCadence) {
        self.count = count
        self.cadence = cadence
        label = cadence == .weekly ? String(localized: "this week") : String(localized: "today")
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
    calendar.locale = .autoupdatingCurrent
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
                referenceDate: entry.date,
                currentStreak: entry.currentStreak,
                todayCount: entry.todayCount,
                isCurrentPeriodCompleted: entry.isCurrentPeriodCompleted,
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
                referenceDate: entry.date,
                currentStreak: entry.currentStreak,
                todayCount: entry.todayCount,
                isCurrentPeriodCompleted: entry.isCurrentPeriodCompleted,
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor,
                inactiveRatio: inactiveRatio
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
            return .result()
        }

        await MainActor.run {
            store.quickLogEntry(calendarId: calendarId, date: Date())

            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
            impactFeedbackgenerator.prepare()
            impactFeedbackgenerator.impactOccurred()
        }

        return .result()
    }
}
