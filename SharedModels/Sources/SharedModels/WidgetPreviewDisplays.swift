import SwiftUI

public enum WidgetPreviewFamily {
    case small
    case medium
    case large
}

public struct YearProgressWidgetDisplayView: View {
    @Environment(\.locale) private var locale

    public let family: WidgetPreviewFamily
    public let referenceDate: Date
    public let backgroundColor: Color
    public let textPrimaryColor: Color
    public let inactiveRatio: Double
    public let renderingMode: WidgetStyle.RenderingMode

    private var dotSize: CGFloat {
        switch family {
        case .large:
            return 9
        case .medium:
            return 7
        case .small:
            return 5
        }
    }

    public init(
        family: WidgetPreviewFamily,
        referenceDate: Date = Date(),
        backgroundColor: Color,
        textPrimaryColor: Color,
        inactiveRatio: Double = WidgetStyle.futureDotFillRatio,
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.family = family
        self.referenceDate = referenceDate
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.inactiveRatio = inactiveRatio
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack {
            HStack(spacing: 6) {
                if family != .small {
                    Text(selectedYear.description)
                        .font(AppFont.mono(12))
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
                        .fontWeight(.heavy)

                    Text("/")
                        .font(AppFont.mono(12))
                        .foregroundColor(renderingMode.isMonochrome ? .secondary : Color("text-tertiary"))
                }

                Text(String(format: "%.1f%%", progress * 100))
                    .font(AppFont.mono(9))
                    .foregroundColor(renderingMode.isMonochrome ? .secondary : Color("text-secondary"))
                    .fontWeight(.black)

                Spacer()

                Text(LocalizedCountText.daysLeft(numberOfDaysInYear - currentDayNumber, locale: locale))
                    .font(AppFont.mono(9))
                    .foregroundColor(renderingMode.isMonochrome ? .secondary : Color("text-tertiary"))
            }

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            WidgetDotsGrid(count: numberOfDaysInYear, dotSize: dotSize) { day in
                WidgetGridDot(
                    color: colorForDay(day),
                    dotSize: dotSize,
                    accentable: renderingMode.isMonochrome && day == todayIndex
                )
            }
        }
        .padding()
        .background(backgroundColor)
    }

    private var progress: Double {
        guard numberOfDaysInYear > 0 else { return 0 }
        return Double(currentDayNumber) / Double(numberOfDaysInYear)
    }

    private var selectedYear: Int {
        LocalDayCalendar.calendar.component(.year, from: referenceDate)
    }

    private var todayIndex: Int {
        currentDayNumber - 1
    }

    private var currentDayNumber: Int {
        let calendar = LocalDayCalendar.calendar
        let today = calendar.startOfDay(for: referenceDate)

        guard let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) else {
            return 0
        }

        let dayOffset = calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0
        return dayOffset + 1
    }

    private var numberOfDaysInYear: Int {
        let calendar = LocalDayCalendar.calendar
        let startOfYear = DateComponents(year: selectedYear, month: 1, day: 1)
        let endOfYear = DateComponents(year: selectedYear, month: 12, day: 31)
        guard let startDate = calendar.date(from: startOfYear),
              let endDate = calendar.date(from: endOfYear)
        else {
            return 365
        }

        return (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 364) + 1
    }

    private var accentColor: Color {
        renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color("qs-orange")
    }

    private func colorForDay(_ day: Int) -> Color {
        if renderingMode.isMonochrome {
            if day > todayIndex {
                return WidgetStyle.monochromeFutureDotColor()
            }
            return day == todayIndex ? accentColor : WidgetStyle.monochromePastDotColor()
        }

        if day > todayIndex {
            return WidgetStyle.inactiveDotColor(surface: backgroundColor, text: textPrimaryColor, ratio: inactiveRatio)
        }

        if day == todayIndex {
            return accentColor
        }

        return WidgetStyle.blendedColor(base: backgroundColor, overlay: textPrimaryColor, ratio: 0.9)
    }
}

public struct HabitProgressWidgetDisplayView: View {
    public let family: WidgetPreviewFamily
    public let calendar: CustomCalendar?
    public let referenceDate: Date
    public let backgroundColor: Color
    public let textPrimaryColor: Color
    public let renderingMode: WidgetStyle.RenderingMode

    private var dotSize: CGFloat {
        switch family {
        case .medium:
            return 7
        case .small, .large:
            return 10
        }
    }

    public init(
        family: WidgetPreviewFamily,
        calendar: CustomCalendar?,
        referenceDate: Date = Date(),
        backgroundColor: Color,
        textPrimaryColor: Color,
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.family = family
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text(calendar?.name ?? String(localized: "Daily Training"))
                    .font(AppFont.mono(12))
                    .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
                    .fontWeight(.heavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer()

                if family != .small, let calendar {
                    let streak = WidgetStreak.currentStreak(calendar: calendar).streak
                    if streak > 0 {
                        Text(LocalizedCountText.currentStreak(streak, cadence: calendar.cadence))
                            .font(AppFont.mono(9))
                            .foregroundColor(renderingMode.isMonochrome ? .secondary : Color("text-tertiary"))
                            .lineLimit(1)
                    }
                }

                HabitQuickAddAffordance(
                    calendar: calendar ?? WidgetPreviewFixtures.habitCalendar(referenceDate: referenceDate),
                    referenceDate: referenceDate,
                    renderingMode: renderingMode
                )
                .frame(width: 24, height: 24)
            }

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            WidgetDotsGrid(count: dates.count, dotSize: dotSize) { index in
                WidgetGridDot(color: colorForDate(dates[index]), dotSize: dotSize)
            }
        }
        .padding()
        .background(backgroundColor)
    }

    private var dates: [Date] {
        switch family {
        case .small:
            return recentDates(days: 35)
        case .medium, .large:
            return yearDates()
        }
    }

    private func colorForDate(_ date: Date) -> Color {
        let normalized = calendar?.bucketDate(for: date) ?? LocalDayCalendar.startOfDay(for: date)
        let today = calendar?.bucketDate(for: referenceDate) ?? LocalDayCalendar.startOfDay(for: referenceDate)

        if renderingMode.isMonochrome {
            if normalized > today {
                return WidgetStyle.monochromeFutureDotColor()
            }
            guard let calendar, let entry = calendar.entry(for: normalized), entry.completed || entry.count > 0 else {
                return WidgetStyle.monochromePastDotColor()
            }
            return normalized == today ? WidgetStyle.monochromeAccentColor() : WidgetStyle.monochromePrimaryColor().opacity(0.85)
        }

        if normalized > today {
            return WidgetStyle.futureDotColor(surface: backgroundColor, text: textPrimaryColor)
        }

        guard let calendar, let entry = calendar.entry(for: normalized) else {
            return normalized == today
                ? WidgetStyle.activeDotColor(surface: backgroundColor, text: textPrimaryColor)
                : WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
        }

        switch calendar.trackingType {
        case .binary:
            return entry.completed ? Color(calendar.color) : WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
        case .counter:
            guard entry.count > 0 else {
                return WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
            }
            return WidgetStyle.blendedColor(
                base: backgroundColor,
                overlay: Color(calendar.color),
                ratio: counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map(\.count))
            )
        case .multipleDaily:
            guard entry.count > 0 else {
                return WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
            }
            return Color(calendar.color).opacity(multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget))
        }
    }

    private func recentDates(days: Int) -> [Date] {
        let end = LocalDayCalendar.startOfDay(for: referenceDate)
        guard let start = LocalDayCalendar.calendar.date(byAdding: .day, value: -(days - 1), to: end) else {
            return [end]
        }
        return buildDates(from: start, to: end)
    }

    private func yearDates() -> [Date] {
        let calendar = LocalDayCalendar.calendar
        let year = calendar.component(.year, from: referenceDate)
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
        else {
            return []
        }
        return buildDates(from: start, to: end)
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
}

public struct StreakWidgetDisplayView: View {
    public let calendarName: String
    public let accentColor: Color
    public let streak: Int
    public let isAtRisk: Bool
    public let backgroundColor: Color
    public let textPrimaryColor: Color
    public let secondaryTextColor: Color
    public let renderingMode: WidgetStyle.RenderingMode

    public init(
        calendarName: String,
        accentColor: Color,
        streak: Int,
        isAtRisk: Bool,
        backgroundColor: Color,
        textPrimaryColor: Color,
        secondaryTextColor: Color = Color("text-secondary"),
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.calendarName = calendarName
        self.accentColor = accentColor
        self.streak = streak
        self.isAtRisk = isAtRisk
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.secondaryTextColor = secondaryTextColor
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack {
                if streak > 0 && !isAtRisk {
                    Text(String(format: String(localized: "your current %@ streak is:"), calendarName.lowercased()))
                } else if streak > 0 && isAtRisk {
                    Text(String(format: String(localized: "your current %@ streak is at risk"), calendarName.lowercased()))
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("qs-red"))
                        .widgetAccentable(renderingMode.isMonochrome)
                } else {
                    Text(calendarName.lowercased())
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
                }
            }
            .foregroundColor(secondaryTextColor)
            .font(AppFont.mono(10))

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            Spacer()

            if streak > 0 {
                Text("\(streak)")
                    .font(AppFont.mono(48))
                    .foregroundColor(accentColor)
                    .fontWeight(.heavy)
                    .widgetAccentable(renderingMode.isMonochrome)
            } else {
                Text(String(localized: "It's never late to start a new streak!"))
                    .font(AppFont.mono(12))
                    .foregroundColor(textPrimaryColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
    }
}

public struct HabitQuickAddAffordance: View {
    public let calendar: CustomCalendar
    public let referenceDate: Date
    public let renderingMode: WidgetStyle.RenderingMode

    public init(
        calendar: CustomCalendar,
        referenceDate: Date = Date(),
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.renderingMode = renderingMode
    }

    public var body: some View {
        let isCompleted = calendar.entry(for: referenceDate)?.completed == true
        let color = renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color(calendar.color)

        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(renderingMode.isMonochrome ? 0.18 : 0.1))
                .frame(width: 24, height: 24)

            Image(systemName: calendar.trackingType == .binary && isCompleted ? "minus" : "plus")
                .font(.system(size: 16))
                .foregroundColor(color)
                .widgetAccentable(renderingMode.isMonochrome)
        }
    }
}

public enum WidgetPreviewFixtures {
    public static func habitCalendar(referenceDate: Date = Date()) -> CustomCalendar {
        CustomCalendar(
            name: String(localized: "Daily Training"),
            color: "qs-orange",
            cadence: .daily,
            trackingType: .binary,
            trackingStartedAt: previewTrackingStart(referenceDate: referenceDate),
            dailyTarget: 1,
            entries: binaryEntries(referenceDate: referenceDate),
            isArchived: false,
            recurringReminderEnabled: true,
            unit: UnitOfMeasure.none,
            defaultRecordValue: 1
        )
    }

    public static func counterCalendar(referenceDate: Date = Date()) -> CustomCalendar {
        CustomCalendar(
            name: String(localized: "Reading"),
            color: "mood-excellent",
            cadence: .daily,
            trackingType: .counter,
            trackingStartedAt: previewTrackingStart(referenceDate: referenceDate),
            dailyTarget: 1,
            entries: counterEntries(referenceDate: referenceDate),
            isArchived: false,
            recurringReminderEnabled: true,
            unit: .pages,
            defaultRecordValue: 10
        )
    }

    private static func binaryEntries(referenceDate: Date) -> [String: CalendarEntry] {
        let offsets = [-28, -27, -25, -24, -23, -21, -20, -19, -18, -16, -15, -14, -13, -12, -10, -9, -8, -7, -5, -4, -3, -2, -1, 0]
        return Dictionary(uniqueKeysWithValues: offsets.compactMap { offset in
            guard let date = LocalDayCalendar.calendar.date(byAdding: .day, value: offset, to: referenceDate) else {
                return nil
            }
            return (DayKeyFormatter.shared.string(from: date), CalendarEntry(date: date, count: 1, completed: true))
        })
    }

    private static func previewTrackingStart(referenceDate: Date) -> Date {
        LocalDayCalendar.calendar.date(byAdding: .day, value: -42, to: referenceDate) ?? referenceDate
    }

    private static func counterEntries(referenceDate: Date) -> [String: CalendarEntry] {
        let countsByOffset = [
            -13: 12, -12: 20, -11: 8, -10: 28, -9: 16, -8: 32, -7: 24,
            -6: 0, -5: 18, -4: 40, -3: 26, -2: 34, -1: 22, 0: 30,
        ]
        return Dictionary(uniqueKeysWithValues: countsByOffset.compactMap { offset, count in
            guard let date = LocalDayCalendar.calendar.date(byAdding: .day, value: offset, to: referenceDate) else {
                return nil
            }
            return (DayKeyFormatter.shared.string(from: date), CalendarEntry(date: date, count: count, completed: count > 0))
        })
    }
}

private struct WidgetDotsGrid<Dot: View>: View {
    let count: Int
    let dotSize: CGFloat
    @ViewBuilder let dot: (Int) -> Dot

    var body: some View {
        GeometryReader { geometry in
            let layout = WidgetStyle.gridLayout(
                count: count,
                dotSize: dotSize,
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height
            )

            VStack(spacing: layout.verticalSpacing) {
                ForEach(0 ..< layout.rows, id: \.self) { row in
                    HStack(spacing: layout.horizontalSpacing) {
                        ForEach(0 ..< layout.columns, id: \.self) { column in
                            let index = row * layout.columns + column
                            if index < count {
                                dot(index)
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
}
