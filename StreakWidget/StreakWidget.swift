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

    func placeholder(in _: Context) -> SimpleEntry {
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

    func snapshot(for configuration: ConfigurationAppIntent, in _: Context) async -> SimpleEntry {
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

    func timeline(for configuration: ConfigurationAppIntent, in _: Context) async -> Timeline<SimpleEntry> {
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
            return calendars.first(where: { $0.id.uuidString == selectedId })
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

struct StreakWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        let renderingMode = WidgetStyle.RenderingMode(widgetRenderingMode)
        let backgroundColor = WidgetStyle.widgetBackgroundColor(for: colorScheme, renderingMode: renderingMode)
        let primaryTextColor = WidgetStyle.primaryTextColor(for: colorScheme, renderingMode: renderingMode)
        let secondaryTextColor = WidgetStyle.secondaryTextColor(for: colorScheme, renderingMode: renderingMode)
        let accentColor = renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color(entry.calendar?.color ?? "qs-orange")
        let calendarName = entry.calendar?.name ?? String(localized: "Habit")
        let streakValue = entry.streak
        let isAtRisk = entry.isAtRisk
        let destinationURL = entry.calendar.map { calendar in
            URL(string: "my-year://calendar/\(calendar.id.uuidString)")
        } ?? nil

        VStack(alignment: .leading, spacing: 6) {
            VStack {
                if streakValue > 0 && !isAtRisk {
                    Text(
                        String(
                            format: String(localized: "your current %@ streak is:"),
                            calendarName.lowercased()
                        )
                    )
                } else if streakValue > 0 && isAtRisk {
                    Text(
                        String(
                            format: String(localized: "your current %@ streak is at risk"),
                            calendarName.lowercased()
                        )
                    )
                    .foregroundColor(renderingMode.isMonochrome ? .primary : Color("qs-red"))
                    .widgetAccentable(renderingMode.isMonochrome)
                } else {
                    Text(calendarName.lowercased())
                        .foregroundColor(renderingMode.isMonochrome ? .primary : .textPrimary)
                }
            }
            .foregroundColor(secondaryTextColor)
            .font(AppFont.mono(10))

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            Spacer()

            if streakValue > 0 {
                Text("\(streakValue)")
                    .font(AppFont.mono(48))
                    .foregroundColor(accentColor)
                    .fontWeight(.heavy)
                    .widgetAccentable(renderingMode.isMonochrome)
            } else {
                Text("It's never late to start a new streak!")
                    .font(AppFont.mono(12))
                    .foregroundColor(primaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(backgroundColor, for: .widget)
        .background(backgroundColor)
        .widgetAccentable(false)
        .widgetURL(destinationURL)
    }
}

struct StreakWidget: Widget {
    let kind: String = WidgetKinds.streak

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
