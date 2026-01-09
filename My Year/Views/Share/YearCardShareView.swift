import SharedModels
import SwiftDate
import SwiftUI

struct YearCardShareView: View {
  let calendar: CustomCalendar
  let year: Int
  let dates: [Date]
  let stats: CalendarStats
  let completionRate30d: Double
  let todaysCount: Int
  let trackingType: TrackingType

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header

      CustomSeparator()
        .padding(.horizontal, -28)

      ShareCalendarGridView(calendar: calendar, dates: dates)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      statsSection

      CustomSeparator()
        .padding(.horizontal, -28)
      footer
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color("surface-muted"))
        .overlay(NoiseLayer(opacity: 1, blendMode: nil))
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color("devider-top"), lineWidth: 1)
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(calendar.name.capitalized)
        .font(.system(size: 18, design: .monospaced))
        .foregroundColor(Color("text-primary"))
        .fontWeight(.black)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }
  }

  private var statsSection: some View {
    VStack(spacing: 12) {
      CustomSeparator()
        .padding(.horizontal, -28)
      HStack {
        Text("Statistics")
          .font(.system(size: 16, design: .monospaced))
          .foregroundColor(Color("text-primary"))
          .fontWeight(.black)
        Spacer()
      }
      HStack(spacing: 12) {
        ShareCompactStatTile(
          title: "Today",
          value: "\(todaysCount)",
          accentColor: Color(calendar.color)
        )
        ShareCompactStatTile(
          title: "Total",
          value: "\(stats.totalCount)",
          accentColor: Color(calendar.color)
        )
        if trackingType != .binary {
          ShareCompactStatTile(
            title: "Best Day",
            value: "\(stats.maxCount)",
            accentColor: Color(calendar.color)
          )
        }
      }
      HStack(spacing: 12) {
        ShareCompactStatTile(
          title: "Current Streak",
          value: "\(stats.currentStreak)",
          accentColor: Color(calendar.color)
        )
        ShareCompactStatTile(
          title: "Longest Streak",
          value: "\(stats.longestStreak)",
          accentColor: Color(calendar.color)
        )
        ShareCompactStatTile(
          title: "30d",
          value: percent(completionRate30d),
          accentColor: Color(calendar.color)
        )
      }
    }
  }

  private var footer: some View {
    HStack {
      Spacer()
      Text("tracked using")
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color("text-tertiary"))
        + Text(" yearlit")
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color("text-primary"))

        Image("icon").resizable().frame(width: 16, height: 16)
    }
  }
}

private struct ShareCompactStatTile: View {
  let title: String
  let value: String
  let accentColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(value)
        .font(.system(size: 24, design: .monospaced))
        .foregroundColor(accentColor)
        .fontWeight(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct ShareCalendarGridView: View {
  let mappedDays: [(date: Date, color: Color)]

  init(calendar: CustomCalendar, dates: [Date]) {
    let today = Date().date
    let maxCount = getMaxCount(calendar: calendar)
    self.mappedDays = dates.map { date in
      (date: date, color: colorForDay(date, calendar: calendar, today: today, maxCount: maxCount))
    }
  }

  var body: some View {
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 0
      let availableWidth = max(0, geometry.size.width - (padding * 2))
      let availableHeight = max(1, geometry.size.height - (padding * 2))
      let aspectRatio = max(0.001, availableWidth / availableHeight)
      let columns = adjustedColumns(for: mappedDays.count, aspectRatio: aspectRatio)
      let rows = max(1, Int(ceil(Double(mappedDays.count) / Double(columns))))
      let horizontalSpacing = (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(2, columns - 1))
      let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(2, rows - 1))

      VStack(spacing: verticalSpacing) {
        ForEach(0..<rows, id: \.self) { row in
          HStack(spacing: horizontalSpacing) {
            ForEach(0..<columns, id: \.self) { col in
              let day = row * columns + col
              if day < mappedDays.count {
                GridDot(
                  color: mappedDays[day].color,
                  dotSize: dotSize
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

private func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
  let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
  var columns = max(1, min(targetColumns, count))
  while columns > 1 && count % columns == 1 {
    columns -= 1
  }
  return columns
}

private func percent(_ value: Double) -> String {
  let clamped = max(0, min(1, value))
  return String(format: "%.0f%%", clamped * 100)
}
