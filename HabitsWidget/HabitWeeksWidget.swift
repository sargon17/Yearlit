//
//  HabitWeeksWidget.swift
//  HabitsWidget
//
//  Lock Screen widget: the last weeks of one habit as a small grid.
//

import SharedModels
import SwiftUI
import WidgetKit

private let weekRows = 3
private let daysPerWeek = 7

struct HabitWeeksWidgetEntryView: View {
  var entry: SimpleEntry
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var widgetRenderingMode

  private let visualizationStyle = GridVisualizationStyle.stored()

  var body: some View {
    let renderingMode = WidgetStyle.RenderingMode(widgetRenderingMode)
    let snapshot = HabitWidgetGridSnapshot.make(
      family: .accessoryRectangular,
      calendar: entry.calendar,
      timelineMode: entry.timelineMode,
      referenceDate: entry.date,
      backgroundColor: WidgetStyle.widgetBackgroundColor(for: colorScheme, renderingMode: renderingMode),
      textPrimaryColor: WidgetStyle.primaryTextColor(for: colorScheme, renderingMode: renderingMode),
      inactiveRatio: WidgetStyle.futureDotFillRatio,
      renderingMode: renderingMode
    )

    VStack(alignment: .leading, spacing: 2) {
      if let calendar = entry.calendar {
        Text(calendar.name)
          .font(AppFont.mono(11))
          .fontWeight(.heavy)
          .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }

      HabitWeeksDotGrid(days: snapshot.days, style: visualizationStyle)
    }
    .containerBackground(.clear, for: .widget)
    .widgetURL(
      entry.calendar.map { calendar in
        widgetDeepLink(
          host: "calendar",
          calendarId: calendar.id.uuidString,
          widgetKind: WidgetAnalyticsKind.habitWeeks.rawValue,
          widgetAction: "open_calendar"
        )
      }
    )
  }
}

private struct HabitWeeksDotGrid: View {
  let days: [HabitWidgetGridDay]
  let style: GridVisualizationStyle

  var body: some View {
    GeometryReader { geometry in
      let columns = CGFloat(daysPerWeek)
      let rows = CGFloat(weekRows)
      let dotSize = min(geometry.size.height / rows, geometry.size.width / columns) * 0.62
      let horizontalSpacing = max(1, (geometry.size.width - dotSize * columns) / (columns - 1))
      let verticalSpacing = max(1, (geometry.size.height - dotSize * rows) / (rows - 1))

      VStack(spacing: verticalSpacing) {
        ForEach(0..<weekRows, id: \.self) { row in
          HStack(spacing: horizontalSpacing) {
            ForEach(0..<daysPerWeek, id: \.self) { col in
              let index = (row * daysPerWeek) + col
              if index < days.count {
                let gridDay = days[index]
                WidgetGridDot(
                  color: gridDay.color,
                  dotSize: dotSize,
                  accentable: gridDay.accentable,
                  style: style,
                  fillRatio: gridDay.fillRatio
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
}

struct HabitWeeksWidget: Widget {
  let kind: String = WidgetKinds.habitWeeks

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: ConfigurationAppIntent.self,
      provider: Provider(analyticsKind: .habitWeeks)
    ) { entry in
      HabitWeeksWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Recent Weeks")
    .description("The last weeks of your habit, on the Lock Screen.")
    .supportedFamilies([.accessoryRectangular])
  }
}
