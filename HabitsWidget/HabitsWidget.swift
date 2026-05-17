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
    private let localCalendar = makeLocalCalendar()

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

    private func colorForDay(_ date: Date, today: Date, your365CellsByDate: [Date: Your365Cell]) -> Color {
        let normalized = normalizedBucketDate(for: date)
        let normalizedToday = normalizedBucketDate(for: today)

        if let cell = your365CellsByDate[normalized] {
            if cell.state == .completed,
               let calendar,
               let entry = calendar.entry(for: normalized) {
                return completedColor(for: entry, today: today)
            }

            return colorForYour365Cell(cell)
        }

        if renderingMode.isMonochrome {
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

                return entry.completed ? WidgetStyle.monochromePrimaryColor().opacity(0.85) : WidgetStyle.monochromePastDotColor()
            case .counter:
                guard entry.count > 0 else {
                    return WidgetStyle.monochromePastDotColor()
                }

                let ratio = max(0.35, counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map { $0.count }))

                if normalized == normalizedToday {
                    return WidgetStyle.monochromeAccentColor().opacity(ratio)
                }

                return WidgetStyle.monochromePrimaryColor().opacity(ratio)
            case .multipleDaily:
                guard entry.count > 0 else {
                    return WidgetStyle.monochromePastDotColor()
                }

                let opacity = max(0.35, multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget))

                if normalized == normalizedToday {
                    return WidgetStyle.monochromeAccentColor().opacity(opacity)
                }

                return WidgetStyle.monochromePrimaryColor().opacity(opacity)
            }
        }

        if normalized > normalizedToday {
            return futureDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
        }

        if let calendar = calendar,
           let entry = calendar.entry(for: normalized)
        {
            switch calendar.trackingType {
            case .binary:
                return entry.completed
                    ? completedColor(for: entry, today: today)
                    : emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
            case .counter:
                if entry.count > 0 {
                    let ratio = counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map { $0.count })
                    return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
                }
                return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
            case .multipleDaily:
                if entry.count > 0 {
                    let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
                    return Color(calendar.color).opacity(opacity)
                }
                return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
            }
        }

        return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
    }

    private func isAccentedDay(_ date: Date, today: Date) -> Bool {
        guard renderingMode.isMonochrome else {
            return false
        }

        let normalized = normalizedBucketDate(for: date)
        let normalizedToday = normalizedBucketDate(for: today)

        guard normalized <= normalizedToday, let calendar, let entry = calendar.entry(for: normalized) else {
            return false
        }

        switch calendar.trackingType {
        case .binary:
            return normalized == normalizedToday && entry.completed
        case .counter, .multipleDaily:
            return normalized == normalizedToday && entry.count > 0
        }
    }

    private func emptyDotColor(for normalized: Date, today: Date, your365CellsByDate: [Date: Your365Cell]) -> Color {
        if let cell = your365CellsByDate[normalized] {
            return colorForYour365Cell(cell)
        }

        normalized == normalizedBucketDate(for: today)
            ? activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
            : missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }

    private func normalizedBucketDate(for date: Date) -> Date {
        if calendar?.cadence == .weekly {
            return LocalDayCalendar.startOfWeek(for: date)
        }

        return localCalendar.startOfDay(for: date)
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
                            Link(destination: URL(string: "my-year://quick-add/\(calendar.id.uuidString)")!) {
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
                let snapshot = your365Snapshot(today: referenceDate)
                let cells = snapshot?.cells ?? []
                let cellsByDate: [Date: Your365Cell] = Dictionary(uniqueKeysWithValues: cells.map { ($0.date, $0) })
                let dates = datesForFamily(today: referenceDate, your365Snapshot: snapshot)
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
                                        color: colorForDay(
                                            dates[day],
                                            today: referenceDate,
                                            your365CellsByDate: cellsByDate
                                        ),
                                        dotSize: dotSize,
                                        accentable: isAccentedDay(dates[day], today: referenceDate)
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

    private func datesForFamily(today: Date, your365Snapshot: Your365Snapshot?) -> [Date] {
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

        if let snapshot = your365Snapshot {
            return snapshot.cells.map(\.date)
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

    private func completedColor(for entry: CalendarEntry, today: Date) -> Color {
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
                let ratio = max(0.35, counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map { $0.count }))

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
            let ratio = counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map { $0.count })
            return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
        case .multipleDaily:
            let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
            return Color(calendar.color).opacity(opacity)
        }
    }
}

struct QuickAddButtonContent: View {
    let calendar: CustomCalendar
    let isCurrentPeriodCompleted: Bool
    let renderingMode: WidgetStyle.RenderingMode

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor().opacity(0.16) : Color(calendar.color).opacity(0.1))
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
    let label: String

    init(numberOfDays: Int, cadence: CalendarCadence, renderingMode: WidgetStyle.RenderingMode) {
        self.numberOfDays = numberOfDays
        self.cadence = cadence
        self.renderingMode = renderingMode
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
                .widgetAccentable(renderingMode.isMonochrome)

            Text(" \(label)")
                .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary"))
        }
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary"))
        .font(AppFont.mono(9))
        .contentTransition(.numericText())
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
                .widgetAccentable(renderingMode.isMonochrome && count > 0)

            Text(" \(label)")
                .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary"))
        }
        .lineLimit(1)
        .foregroundColor(renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary"))
        .font(AppFont.mono(9))
        .contentTransition(.numericText())
    }
}

private func makeLocalCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = .autoupdatingCurrent
    calendar.timeZone = .autoupdatingCurrent
    return calendar
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

struct HabitsWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        let destinationURL = entry.calendar.map { calendar in
            URL(string: "my-year://calendar/\(calendar.id.uuidString)")
        } ?? nil
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
