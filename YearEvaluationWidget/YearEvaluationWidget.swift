//
//  YearEvaluationWidget.swift
//  YearEvaluationWidget
//
//  Created by Mykhaylo Tymofyeyev  on 14/01/25.
//

import WidgetKit
import SwiftUI
import SharedModels
import AppIntents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let valuations: [String: DayValuation]
    var visualizationType: VisualizationType
}

struct ToggleVisualizationIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Visualization"
    static var description = IntentDescription("Changes how the year is visualized")

    private let defaults = UserDefaults(suiteName: "group.sargon17.My-Year")
    private let visualizationTypeKey = "widget.visualizationType"

    func perform() async throws -> some IntentResult {
        let currentType = defaults?.string(forKey: visualizationTypeKey).flatMap { VisualizationType(rawValue: $0) } ?? .full
        let nextType: VisualizationType = {
            switch currentType {
            case .full: return .pastOnly
            case .pastOnly: return .evaluatedOnly
            case .evaluatedOnly: return .full
            }
        }()
        
        defaults?.set(nextType.rawValue, forKey: visualizationTypeKey)
        defaults?.synchronize()
        
        await WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry
    let store = ValuationStore.shared
    private let defaults = UserDefaults(suiteName: "group.sargon17.My-Year")
    private let visualizationTypeKey = "widget.visualizationType"

    private func getCurrentVisualizationType() -> VisualizationType {
        defaults?.string(forKey: visualizationTypeKey).flatMap { VisualizationType(rawValue: $0) } ?? .full
    }

    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), valuations: [:], visualizationType: getCurrentVisualizationType())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        print("Widget: Getting snapshot")
        store.loadValuations()
        let entry = SimpleEntry(date: Date(), valuations: store.valuations, visualizationType: getCurrentVisualizationType())
        print("Widget snapshot valuations: \(entry.valuations.count)")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("Widget: Getting timeline")
        store.loadValuations()
        
        // Create a single entry with current data
        let entry = SimpleEntry(date: Date(), valuations: store.valuations, visualizationType: getCurrentVisualizationType())
        print("Widget timeline valuations: \(entry.valuations.count)")
        
        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct YearEvaluationWidgetEntryView : View {
    var entry: Provider.Entry
    let store = ValuationStore.shared
    @State private var dayTypesQuantity: [DayMoodType: Int] = [:]
    
    init(entry: Provider.Entry) {
        self.entry = entry
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(store.year.description)")
                    .font(.system(size: 28))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)

                Spacer()

                Text("Left: ")
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                + Text("\(store.numberOfDaysInYear - store.currentDayNumber)")
                    .font(.system(size: 20))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)
            }
            .foregroundColor(Color("text-primary").opacity(0.5))
            .fontWeight(.regular)

            MosaicChart(
                dayTypesQuantity: dayTypesQuantity,
                visualizationType: entry.visualizationType
            )
            .frame(height: 60)
            .onTapGesture {
                Task {
                    try? await ToggleVisualizationIntent().perform()
                }
            }
        }
        .onAppear {
            dayTypesQuantity = SharedModels.updateDayTypesQuantity(store: store)
        }
    }
}

struct YearEvaluationWidget: Widget {
    let kind: String = "YearEvaluationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                YearEvaluationWidgetEntryView(entry: entry)
                    .containerBackground(Color("surface-muted"), for: .widget)
            } else {
                YearEvaluationWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.clear)
            }
        }
        .configurationDisplayName("Year Evaluation Widget")
        .description("This widget shows the evaluation of your year.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    YearEvaluationWidget()
} timeline: {
    SimpleEntry(date: .now, valuations: [:], visualizationType: .full)
    SimpleEntry(date: .now, valuations: [:], visualizationType: .pastOnly)
}
