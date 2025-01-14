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
    
    init(family: WidgetFamily, valuations: [String: DayValuation]) {
        self.family = family
        self.valuations = valuations
        switch family {
        case .systemLarge:
            self.dotSize = 6.0
        case .systemMedium:
            self.dotSize = 6.0
        default:
            self.dotSize = 4.0
        }
    }
    
    private func colorForDay(_ day: Int) -> Color {
        let dayDate = store.dateForDay(day)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: dayDate)
        
        if day >= store.currentDayNumber {
            return Color("dot-inactive")
        }
        
        if let valuation = valuations[key] {
            return Color(valuation.mood.color)
        }
        
        return Color("dot-active")
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 6) {
                if family == .systemLarge || family == .systemMedium {
                    Text(Calendar.current.component(.year, from: Date()).description)
                        .font(.system(size: 12))
                        .foregroundColor(Color("text-primary"))
                        .fontWeight(.bold)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color("dot-active"))
                        .frame(width: 4, height: 4)
                }

                let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
                Text(String(format: "%.1f%%", percent * 100))
                    .font(.system(size: 12))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.bold)
                Spacer()
                
                HStack {
                    Text("Left: ")
                        .font(.system(size: 9))
                        .foregroundColor(Color("text-primary").opacity(0.5))
                        .fontWeight(.regular)
                    + Text("\(store.numberOfDaysInYear - store.currentDayNumber)")
                        .font(.system(size: 12))
                        .foregroundColor(Color("text-primary"))
                        .fontWeight(.bold)
                }
            }

            
            GeometryReader { geometry in
                let aspectRatio = geometry.size.width / geometry.size.height
                let targetColumns = Int(sqrt(Double(365) * aspectRatio))
                let columns = min(targetColumns, 365)
                let rows = Int(ceil(Double(365) / Double(columns)))
                
                let horizontalSpacing = (geometry.size.width - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
                let verticalSpacing = (geometry.size.height - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)
                
                VStack(spacing: verticalSpacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: horizontalSpacing) {
                            ForEach(0..<columns, id: \.self) { col in
                                let day = row * columns + col
                                if day < store.numberOfDaysInYear {
                                    let color = colorForDay(day)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(color)
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
        .background(Color.clear)
    }
}

struct YearWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack {
            HorizontalYearGrid(family: family, valuations: entry.valuations)
        }
        .containerBackground(Color("surface-muted"), for: .widget)
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
