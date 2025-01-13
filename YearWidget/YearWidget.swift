import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let nextUpdate = Date().addingTimeInterval(86400) // 24 hours
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct HorizontalYearGrid: View {
    let dotSize: CGFloat
    let family: WidgetFamily
    
    init(family: WidgetFamily) {
        self.family = family
        // Adjust dot size based on widget size
        switch family {
        case .systemLarge:
            self.dotSize = 6.0
        case .systemMedium:
            self.dotSize = 6.0
        default:
            self.dotSize = 4.0
        }
    }
    
    var year: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var currentDay: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 6) {
                if family == .systemLarge || family == .systemMedium {
                    Text(year.description).font(.system(size: 12)).foregroundColor(Color("text-primary")).fontWeight(.bold)
                    RoundedRectangle(cornerRadius: 1).fill(Color("dot-active")).frame(width: 4, height: 4)
                }

                let percent = Double(currentDay) / 365.0
                Text(String(format: "%.1f%%", percent * 100)).font(.system(size: 12)).foregroundColor(Color("text-primary")).fontWeight(.bold)
                Spacer()
                
                HStack {
                    Text("Left: ").font(.system(size: 9)).foregroundColor(Color("text-primary").opacity(0.5)).fontWeight(.regular)
                    + Text("\(365 - currentDay)").font(.system(size: 12)).foregroundColor(Color("text-primary")).fontWeight(.bold)
                }


            
            }
            GeometryReader { geometry in
                // Calculate grid dimensions based on aspect ratio
                let aspectRatio = geometry.size.width / geometry.size.height
                let targetColumns = Int(sqrt(Double(365) * aspectRatio))
                let columns = min(targetColumns, 365)
                let rows = Int(ceil(Double(365) / Double(columns)))
                
            // Calculate spacings to fill the widget
            let horizontalSpacing = (geometry.size.width - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
            let verticalSpacing = (geometry.size.height - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)
            
            VStack(spacing: verticalSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0..<columns, id: \.self) { col in
                            // Calculate day vertically: col * rows + row
                            let day = col * rows + row
                            if day < 365 {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(day < currentDay ? Color("dot-active") : Color("dot-inactive"))
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
    }
}

struct YearWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        HorizontalYearGrid(family: family)
            .containerBackground(Color("surface-muted"), for: .widget)
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

#Preview("Small Widget", as: .systemSmall) {
    YearWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview("Medium Widget", as: .systemMedium) {
    YearWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview("Large Widget", as: .systemLarge) {
    YearWidget()
} timeline: {
    SimpleEntry(date: .now)
} 