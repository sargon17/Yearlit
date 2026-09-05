//
//  HabitWeeksWidget.swift
//  HabitsWidget
//
//  Lock Screen widget: the last weeks of one habit as a small grid.
//

import SharedModels
import SwiftUI
import WidgetKit

private let daysPerRow = 14
private let gapRatio: CGFloat = 0.4

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

    VStack(alignment: .leading, spacing: 6) {
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
      let columns = CGFloat(daysPerRow)
      let dotSize = geometry.size.width / (columns + ((columns - 1) * gapRatio))
      let horizontalSpacing = dotSize * gapRatio
      let rowsThatFit = Int((geometry.size.height + horizontalSpacing) / (dotSize + horizontalSpacing))
      let rows = min(days.count / daysPerRow, rowsThatFit)
      let verticalSpacing = rows > 1
        ? (geometry.size.height - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)
        : 0
      let shown = Array(days.suffix(rows * daysPerRow))

      VStack(spacing: verticalSpacing) {
        ForEach(0..<rows, id: \.self) { row in
          HStack(spacing: horizontalSpacing) {
            ForEach(0..<daysPerRow, id: \.self) { col in
              let gridDay = shown[(row * daysPerRow) + col]
              WidgetGridDot(
                color: gridDay.color,
                dotSize: dotSize,
                accentable: gridDay.accentable,
                style: style,
                fillRatio: gridDay.fillRatio
              )
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
