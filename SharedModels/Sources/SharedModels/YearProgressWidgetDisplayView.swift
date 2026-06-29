import SwiftUI

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
