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
    let mappedDays: [(date: Date, color: Color)]

    init(calendar: CustomCalendar, dates: [Date]) {
        let today = Date().date
        let counts = calendar.entries.values.map { $0.count }
        mappedDays = dates.map { date in
            (date: date, color: colorForDay(date, calendar: calendar, today: today, counts: counts))
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
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
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

func sharePercent(_ value: Double) -> String {
    let clamped = max(0, min(1, value))
    return String(format: "%.0f%%", clamped * 100)
}

func shareWeekdayName(_ idx: Int) -> String {
    let symbols = Calendar.current.shortWeekdaySymbols
    let clamped = max(1, min(7, idx))
    return symbols[clamped - 1]
}

private func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
    let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
    var columns = max(1, min(targetColumns, count))
    while columns > 1 && count % columns == 1 {
        columns -= 1
    }
    return columns
}
