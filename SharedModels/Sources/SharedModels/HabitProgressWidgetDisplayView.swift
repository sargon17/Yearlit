import SwiftUI

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
            return WidgetDateRange.recentDays(endingAt: referenceDate, count: 35)
        case .medium, .large:
            return WidgetDateRange.daysInYear(containing: referenceDate)
        }
    }

    private func colorForDate(_ date: Date) -> Color {
        let normalized = calendar?.bucketDate(for: date) ?? LocalDayCalendar.startOfDay(for: date)
        let today = calendar?.bucketDate(for: referenceDate) ?? LocalDayCalendar.startOfDay(for: referenceDate)

        if renderingMode.isMonochrome {
            if normalized > today {
                return WidgetStyle.monochromeFutureDotColor()
            }
            guard let calendar, let entry = calendar.entry(for: normalized), entry.completed || entry.hasLoggedCount else {
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
            guard entry.hasLoggedCount else {
                return WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
            }
            return WidgetStyle.blendedColor(
                base: backgroundColor,
                overlay: Color(calendar.color),
                ratio: counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map(\.count))
            )
        case .multipleDaily:
            guard entry.hasLoggedCount else {
                return WidgetStyle.missedDotColor(surface: backgroundColor, text: textPrimaryColor)
            }
            return Color(calendar.color).opacity(multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget))
        }
    }
}
