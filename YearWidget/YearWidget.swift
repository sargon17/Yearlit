import WidgetKit
import SwiftUI
import SharedModels
import AppIntents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let valuations: [String: DayValuation]
}

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry
    let store = ValuationStore.shared
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), valuations: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        print("Widget: Getting snapshot")
        store.loadValuations()
        let entry = SimpleEntry(date: Date(), valuations: store.valuations)
        print("Widget snapshot valuations: \(entry.valuations.count)")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("Widget: Getting timeline")
        store.loadValuations()
        
        // Create a single entry with current data
        let entry = SimpleEntry(date: Date(), valuations: store.valuations)
        print("Widget timeline valuations: \(entry.valuations.count)")
        
        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct HorizontalYearGrid: View {
    let dotSize: CGFloat
    let family: WidgetFamily
    let valuations: [String: DayValuation]
    let store = ValuationStore.shared
    let backgroundColor: Color
    let textPrimaryColor: Color
    let inactiveRatio: Double
    
    init(
        family: WidgetFamily,
        valuations: [String: DayValuation],
        backgroundColor: Color,
        textPrimaryColor: Color,
        inactiveRatio: Double
    ) {
        self.family = family
        self.valuations = valuations
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.inactiveRatio = inactiveRatio
        switch family {
        case .systemLarge:
            self.dotSize = 9.0
        case .systemMedium:
            self.dotSize = 7.0
        default:
            self.dotSize = 5.0
        }
    }
    
    private func colorForDay(_ day: Int) -> Color {
        let dayDate = store.dateForDay(day)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: dayDate)
        
        if day >= store.currentDayNumber {
            return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
        }
        
        return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }
    
    var body: some View {
        let today = Date()
        VStack {
            HStack(spacing: 6) {
                if family == .systemLarge || family == .systemMedium {
                    Text(Calendar.current.component(.year, from: Date()).description)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(textPrimaryColor)
                        .fontWeight(.black)
                    WidgetGridDot(color: activeDayColor(base: backgroundColor, overlay: textPrimaryColor), dotSize: 4)
                }

                let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
                Text(String(format: "%.1f%%", percent * 100))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(textPrimaryColor)
                    .fontWeight(.black)
                Spacer()
                
                HStack {
                    Text("Left: ")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(textPrimaryColor.opacity(0.5))
                        .fontWeight(.regular)
                    + Text("\(store.numberOfDaysInYear - store.currentDayNumber)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(textPrimaryColor)
                        .fontWeight(.black)
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
                let totalDays = store.numberOfDaysInYear
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
                                if day < store.numberOfDaysInYear {
                                    let color = colorForDay(day)
                                    WidgetGridDot(color: color, dotSize: dotSize)
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
        .background(Color.clear)
    }
}

struct YearWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let backgroundColor = surfaceMutedColor(for: colorScheme)
        let primaryTextColor = textPrimaryColor(for: colorScheme)
        let inactiveRatio = colorScheme == .dark ? 0.12 : 0.1

        VStack {
            HorizontalYearGrid(
                family: family,
                valuations: entry.valuations,
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor,
                inactiveRatio: inactiveRatio
            )
        }
        .containerBackground(backgroundColor, for: .widget)
        .widgetAccentable(false)
    }
}

struct DebugIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear All Valuations"
    
    func perform() async throws -> some IntentResult {
        let store = ValuationStore.shared
        store.clearAllValuations()
        return .result()
    }
}

struct YearWidget: Widget {
    let kind: String = "YearWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YearWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Year Progress")
        .description("Track your year's progress with a beautiful visualization.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
    blendedColor(base: base, overlay: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
    blendedColor(base: base, overlay: overlay, ratio: 0.9)
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

struct WidgetGridDot: View {
    let color: Color
    let dotSize: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: dotSize, height: dotSize)
            .widgetAccentable(false)
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

#Preview(as: .systemSmall) {
    YearWidget()
} timeline: {
    SimpleEntry(date: Date(), valuations: [:])
}

#Preview(as: .systemMedium) {
    YearWidget()
} timeline: {
    SimpleEntry(date: Date(), valuations: [:])
}

#Preview(as: .systemLarge) {
    YearWidget()
} timeline: {
    SimpleEntry(date: Date(), valuations: [:])
}
