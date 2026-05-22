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

        YearProgressWidgetDisplayView(
            family: family.previewFamily,
            referenceDate: entry.date,
            backgroundColor: backgroundColor,
            textPrimaryColor: primaryTextColor,
            inactiveRatio: inactiveRatio,
            renderingMode: renderingMode
        )
        .containerBackground(backgroundColor, for: .widget)
        .widgetAccentable(false)
        .widgetURL(URL(string: "my-year://?source=widget&widget_kind=year&widget_action=open_app"))
    }
}

private extension WidgetFamily {
    var previewFamily: WidgetPreviewFamily {
        switch self {
        case .systemLarge:
            return .large
        case .systemMedium:
            return .medium
        default:
            return .small
        }
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
    }
}
