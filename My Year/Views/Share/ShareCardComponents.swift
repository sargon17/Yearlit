import SharedModels
import SwiftDate
import SwiftUI

struct ShareCardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
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
}

struct ShareCardFooter: View {
    var body: some View {
        HStack {
            Spacer()
            Text("tracked using")
                .font(AppFont.mono(12))
                .foregroundColor(Color("text-tertiary"))
                + Text(" yearlit")
                .font(AppFont.mono(12))
                .foregroundColor(Color("text-primary"))

            Image("icon")
                .resizable()
                .frame(width: 16, height: 16)
        }
    }
}

struct ShareCompactStatTile: View {
    let title: LocalizedStringKey
    let value: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.mono(10))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(verbatim: value)
                .font(AppFont.mono(24))
                .foregroundColor(accentColor)
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShareCalendarGridView: View {
    let mappedDays: [GridDay]
    private let style = GridVisualizationStyle.stored()

    init(calendar: CustomCalendar, dates: [Date]) {
        let today = Date().date
        let scale = precomputeRobustDotScale(for: calendar.entries.values.map(\.count))
        mappedDays = dates.map { date in
            GridDay(
                date: date,
                color: colorForDay(date, calendar: calendar, today: today, precomputedScale: scale),
                fillRatio: fillRatioForDay(date, calendar: calendar, today: today, precomputedScale: scale)
            )
        }
    }

    init(snapshot: Your365Snapshot, calendar: CustomCalendar, today: Date = Date()) {
        let scale = precomputeRobustDotScale(for: calendar.entries.values.map(\.count))
        mappedDays = snapshot.cells.map { cell in
            let isTracked = cell.state != .future && cell.state != .notTracked
            return GridDay(
                date: cell.date,
                color: colorForYour365Cell(
                    cell,
                    calendar: calendar,
                    today: today,
                    precomputedScale: scale
                ),
                fillRatio: isTracked
                    ? fillRatioForDay(cell.date, calendar: calendar, today: today, precomputedScale: scale)
                    : 0
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let padding: CGFloat = 0
            let availableWidth = max(0, geometry.size.width - (padding * 2))
            let availableHeight = max(1, geometry.size.height - (padding * 2))
            let layout = WidgetStyle.gridLayout(
                count: mappedDays.count,
                dotSize: dotSize,
                availableWidth: availableWidth,
                availableHeight: availableHeight
            )

            VStack(spacing: layout.verticalSpacing) {
                ForEach(0 ..< layout.rows, id: \.self) { row in
                    HStack(spacing: layout.horizontalSpacing) {
                        ForEach(0 ..< layout.columns, id: \.self) { col in
                            let day = row * layout.columns + col
                            if day < mappedDays.count {
                                GridDot(
                                    color: mappedDays[day].color,
                                    dotSize: dotSize,
                                    style: style,
                                    fillRatio: mappedDays[day].fillRatio
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

private func colorForYour365Cell(
    _ cell: Your365Cell,
    calendar: CustomCalendar,
    today: Date,
    precomputedScale: Double
) -> Color {
    switch cell.state {
    case .completed, .missed, .todayPending:
        return colorForDay(
            cell.date,
            calendar: calendar,
            today: today,
            precomputedScale: precomputedScale
        )
    case .future:
        return futureDayColor()
    case .notTracked:
        return missedDayColor().opacity(0.35)
    }
}

func sharePercent(_ value: Double) -> String {
    let clamped = max(0, min(1, value))
    return String(format: "%.0f%%", clamped * 100)
}

func shareWeekdayName(_ idx: Int) -> String {
    let symbols = Calendar.current.shortWeekdaySymbols
    let clamped = max(1, min(7, idx))
    return symbols[clamped - 1]
}
