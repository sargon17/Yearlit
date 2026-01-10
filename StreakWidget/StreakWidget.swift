//
//  StreakWidget.swift
//  StreakWidget
//
//  Created by Mykhaylo Tymofyeyev  on 10/01/26.
//

import SharedModels
import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> SimpleEntry {
        let configuration = ConfigurationAppIntent.defaultCalendar
        let calendar = resolvedCalendar(for: configuration)
        let streakData = calendar.map { WidgetStreak.currentStreak(calendar: $0) }
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            calendar: calendar,
            streak: streakData?.streak ?? 0,
            isAtRisk: streakData?.isAtRisk ?? false
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let calendar = resolvedCalendar(for: configuration)
        let streakData = calendar.map { WidgetStreak.currentStreak(calendar: $0) }
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            calendar: calendar,
            streak: streakData?.streak ?? 0,
            isAtRisk: streakData?.isAtRisk ?? false
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let calendar = resolvedCalendar(for: configuration)
        let streakData = calendar.map { WidgetStreak.currentStreak(calendar: $0) }
        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            calendar: calendar,
            streak: streakData?.streak ?? 0,
            isAtRisk: streakData?.isAtRisk ?? false
        )

        let nextUpdate = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        )

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func resolvedCalendar(for configuration: ConfigurationAppIntent) -> CustomCalendar? {
        let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
        if let selectedId = configuration.selectedCalendar?.id {
            return calendars.first(where: { $0.id.uuidString == selectedId }) ?? calendars.first
        }
        return calendars.first
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let calendar: CustomCalendar?
    let streak: Int
    let isAtRisk: Bool
}

struct StreakWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let backgroundColor = WidgetStyle.surfaceMutedColor(for: colorScheme)
        let primaryTextColor = WidgetStyle.textPrimaryColor(for: colorScheme)
        let accentColor = Color(red: 0xF9 / 255.0, green: 0x73 / 255.0, blue: 0x16 / 255.0)
        let calendarName = entry.calendar?.name ?? "Habit"
        let destinationURL = entry.calendar.map { calendar in
            URL(string: "my-year://calendar/\(calendar.id.uuidString)")
        } ?? nil

        VStack(alignment: .leading, spacing: 6) {
            Text(calendarName)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(primaryTextColor.opacity(0.6))
                .lineLimit(1)

            Spacer()

            if entry.streak > 0 {
                Text("\(entry.streak)")
                    .font(.system(size: 36, design: .monospaced))
                    .foregroundColor(accentColor)
                    .fontWeight(.black)

                if entry.isAtRisk {
                    Text("streak at risk")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(primaryTextColor)
                }
            } else {
                Text("Restart your habit")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(primaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(backgroundColor, for: .widget)
        .widgetAccentable(false)
        .widgetURL(destinationURL)
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("See your current habit streak at a glance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    SimpleEntry(
        date: Date(),
        configuration: ConfigurationAppIntent.defaultCalendar,
        calendar: nil,
        streak: 0,
        isAtRisk: false
    )
}
