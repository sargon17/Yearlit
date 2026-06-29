import AppIntents
import SharedModels
import SwiftUI
import WidgetKit

struct HorizontalCalendarGrid: View {
  let dotSize: CGFloat
  let family: WidgetFamily
  let calendar: CustomCalendar?
  let timelineMode: CalendarTimelineMode
  let referenceDate: Date
  let currentStreak: Int
  let todayCount: Int
  let isCurrentPeriodCompleted: Bool
  let backgroundColor: Color
  let textPrimaryColor: Color
  let inactiveRatio: Double
  let renderingMode: WidgetStyle.RenderingMode

  init(
    family: WidgetFamily,
    calendar: CustomCalendar?,
    timelineMode: CalendarTimelineMode,
    referenceDate: Date,
    currentStreak: Int,
    todayCount: Int,
    isCurrentPeriodCompleted: Bool,
    backgroundColor: Color,
    textPrimaryColor: Color,
    inactiveRatio: Double,
    renderingMode: WidgetStyle.RenderingMode
  ) {
    self.family = family
    self.calendar = calendar
    self.timelineMode = timelineMode
    self.referenceDate = referenceDate
    self.currentStreak = currentStreak
    self.todayCount = todayCount
    self.isCurrentPeriodCompleted = isCurrentPeriodCompleted
    self.backgroundColor = backgroundColor
    self.textPrimaryColor = textPrimaryColor
    self.inactiveRatio = inactiveRatio
    self.renderingMode = renderingMode
    switch family {
    case .systemLarge:
      dotSize = 10.0
    case .systemMedium:
      dotSize = 7
    default:
      dotSize = 10.0
    }
  }

  var body: some View {
    VStack {
      HStack(spacing: 6) {
        if let calendar = calendar {
          Text(calendar.name)
            .font(AppFont.mono(12))
            .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
            .fontWeight(.heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }

        Spacer()

        if let calendar = calendar {
          HStack(spacing: 8) {
            if calendar.trackingType != .binary && family != .systemSmall {
              TodaysCountView(count: todayCount, cadence: calendar.cadence, renderingMode: renderingMode)
            }

            if family != .systemSmall, currentStreak > 0 {
              NumberOfDaysView(
                numberOfDays: currentStreak,
                cadence: calendar.cadence,
                renderingMode: renderingMode
              )
            }

            quickAddButton(for: calendar)
          }
        }
      }

      WidgetSeparator(renderingMode: renderingMode)
        .padding(.horizontal, -16)
        .padding(.bottom, 4)

      GeometryReader { geometry in
        let padding: CGFloat = 0
        let gridSnapshot = HabitWidgetGridSnapshot.make(HabitWidgetGridSnapshotConfiguration(
          family: family,
          calendar: calendar,
          timelineMode: timelineMode,
          referenceDate: referenceDate,
          backgroundColor: backgroundColor,
          textPrimaryColor: textPrimaryColor,
          inactiveRatio: inactiveRatio,
          renderingMode: renderingMode
        ))
        let totalDays = gridSnapshot.days.count
        let availableWidth = geometry.size.width - (padding * 2)
        let availableHeight = geometry.size.height - (padding * 2)
        let layout = WidgetStyle.gridLayout(
          count: totalDays,
          dotSize: dotSize,
          availableWidth: availableWidth,
          availableHeight: availableHeight
        )

        VStack(spacing: layout.verticalSpacing) {
          ForEach(0..<layout.rows, id: \.self) { row in
            HStack(spacing: layout.horizontalSpacing) {
              ForEach(0..<layout.columns, id: \.self) { col in
                let day = row * layout.columns + col
                if day < totalDays {
                  let gridDay = gridSnapshot.days[day]
                  WidgetGridDot(
                    color: gridDay.color,
                    dotSize: dotSize,
                    accentable: gridDay.accentable
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
    .padding()
    .background(backgroundColor)
  }

  @ViewBuilder
  private func quickAddButton(for calendar: CustomCalendar) -> some View {
    if #available(iOS 17.0, *) {
      Button(intent: HabitQuickAddIntent(calendarId: calendar.id.uuidString)) {
        QuickAddButtonContent(
          calendar: calendar,
          renderingMode: renderingMode
        )
      }
      .buttonStyle(.plain)
      .frame(width: 24, height: 24)
    } else {
      if let destination = widgetDeepLink(
        host: "quick-add",
        calendarId: calendar.id.uuidString,
        widgetKind: WidgetAnalyticsKind.habits.rawValue,
        widgetAction: "quick_add"
      ) {
        Link(
          destination: destination
        ) {
          QuickAddButtonContent(
            calendar: calendar,
            renderingMode: renderingMode
          )
        }
        .frame(width: 24, height: 24)
      } else {
        QuickAddButtonContent(
          calendar: calendar,
          renderingMode: renderingMode
        )
        .frame(width: 24, height: 24)
      }
    }
  }
}
