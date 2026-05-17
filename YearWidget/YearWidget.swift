import AppIntents
import SharedModels
import SwiftUI
import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry

    func placeholder(in _: Context) -> SimpleEntry {
        return SimpleEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = SimpleEntry(date: Date())

        if !context.isPreview {
            WidgetAnalyticsQueue.shared.enqueueTimelineLoaded(properties: [
                "widget_kind": .string(WidgetAnalyticsKind.year.rawValue),
                "widget_family": .string(widgetFamilyName(context.family)),
                "has_calendar": .bool(false),
                "timeline_mode": .string("calendarYear")
            ])
        }

        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
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

struct HorizontalYearGrid: View {
    @Environment(\.locale) private var locale
    let dotSize: CGFloat
    let family: WidgetFamily
    let referenceDate: Date
    let backgroundColor: Color
    let textPrimaryColor: Color
    let inactiveRatio: Double
    let renderingMode: WidgetStyle.RenderingMode

    init(
        family: WidgetFamily,
        referenceDate: Date,
        backgroundColor: Color,
        textPrimaryColor: Color,
        inactiveRatio: Double,
        renderingMode: WidgetStyle.RenderingMode
    ) {
        self.family = family
        self.referenceDate = referenceDate
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.inactiveRatio = inactiveRatio
        self.renderingMode = renderingMode
        switch family {
        case .systemLarge:
            dotSize = 9.0
        case .systemMedium:
            dotSize = 7.0
        default:
            dotSize = 5.0
        }
    }

    private func colorForDay(_ day: Int) -> Color {
        let todayIndex = self.todayIndex

        if renderingMode.isMonochrome {
            if day > todayIndex {
                return WidgetStyle.monochromeFutureDotColor()
            }

            if day == todayIndex {
                return accentColor
            }

            return WidgetStyle.monochromePastDotColor()
        }

        if day > todayIndex {
            return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
        }

        if day == todayIndex {
            return accentColor
        }

        return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }

    private var accentColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color("qs-orange")
        case .reduced:
            return WidgetStyle.monochromeAccentColor()
        }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                if family == .systemLarge || family == .systemMedium {
                    Text(LocalDayCalendar.calendar.component(.year, from: referenceDate).description)
                        .font(AppFont.mono(12))
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
                        .fontWeight(.heavy)

                    Text("/")
                        .font(AppFont.mono(12))
                        .foregroundColor(renderingMode.isMonochrome ? .secondary : Color("text-tertiary"))
                }

                let percent = Double(currentDayNumber) / Double(numberOfDaysInYear)
                Text(String(format: "%.1f%%", percent * 100))
                    .font(AppFont.mono(9))
                    .foregroundColor(renderingMode.isMonochrome ? .secondary : .textSecondary)
                    .fontWeight(.black)

                Spacer()

                Text(LocalizedCountText.daysLeft(numberOfDaysInYear - currentDayNumber, locale: locale))
                    .font(AppFont.mono(9))
                    .foregroundColor(renderingMode.isMonochrome ? .secondary : .textTertiary)
            }

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            GeometryReader { geometry in
                let padding: CGFloat = 0
                let totalDays = numberOfDaysInYear
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
                                if day < numberOfDaysInYear {
                                    let color = colorForDay(day)
                                    WidgetGridDot(
                                        color: color,
                                        dotSize: dotSize,
                                        accentable: renderingMode.isMonochrome && day == todayIndex
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
        .padding().background(backgroundColor)
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
}

struct YearWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        let renderingMode = WidgetStyle.RenderingMode(widgetRenderingMode)
        let backgroundColor = WidgetStyle.widgetBackgroundColor(for: colorScheme, renderingMode: renderingMode)
        let primaryTextColor = WidgetStyle.primaryTextColor(for: colorScheme, renderingMode: renderingMode)
        let inactiveRatio = WidgetStyle.futureDotFillRatio

        HorizontalYearGrid(
            family: family,
            referenceDate: entry.date,
            backgroundColor: backgroundColor,
            textPrimaryColor: primaryTextColor,
            inactiveRatio: inactiveRatio,
            renderingMode: renderingMode
        )
        .containerBackground(backgroundColor, for: .widget)
        .widgetAccentable(false)
    }
}

struct YearWidget: Widget {
    let kind: String = WidgetKinds.year

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YearWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Year Progress")
        .description("Track your year's progress with a beautiful visualization.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .widgetURL(URL(string: "my-year://?source=widget&widget_kind=year&widget_action=open_app"))
    }
}

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
    WidgetStyle.inactiveDotColor(surface: base, text: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
    WidgetStyle.blendedColor(base: base, overlay: overlay, ratio: 0.9)
}
