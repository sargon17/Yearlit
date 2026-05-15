import SharedModels
import SwiftUI

struct GridView: View {
    struct Your365Presentation {
        let snapshot: Your365Snapshot
        let cellsByDate: [Date: Your365Cell]

        init(snapshot: Your365Snapshot) {
            self.snapshot = snapshot
            cellsByDate = Dictionary(uniqueKeysWithValues: snapshot.cells.map { ($0.date, $0) })
        }
    }

    let calendar: CustomCalendar
    let handleDayTap: (Date) -> Void
    let dates: [Date]
    let today: Date
    let your365Presentation: Your365Presentation?
    let mappedDays: [(date: Date, color: Color)]

    init(
        calendar: CustomCalendar,
        handleDayTap: @escaping (Date) -> Void,
        dates: [Date],
        today: Date,
        your365Presentation: Your365Presentation?
    ) {
        self.calendar = calendar
        self.handleDayTap = handleDayTap
        self.dates = dates
        self.today = today
        self.your365Presentation = your365Presentation
        self.mappedDays = Self.makeMappedDays(
            calendar: calendar,
            dates: dates,
            today: today,
            your365Presentation: your365Presentation
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let padding: CGFloat = 20

            let availableWidth = max(0, geometry.size.width - (padding * 2))
            let availableHeight = max(1, geometry.size.height - (padding * 2))

            let dayCount = mappedDays.count
            let aspectRatio = max(0.001, availableWidth / availableHeight)
            let targetColumns = Int(sqrt(Double(dayCount) * aspectRatio))
            let columns = max(min(targetColumns, dayCount), 1)
            let rows = max(Int(ceil(Double(dayCount) / Double(columns))), 1)

            let horizontalSpacing =
                max(0, (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
            let verticalSpacing =
                max(0, (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
            let hitSize = dotSize + max(0, min(horizontalSpacing, verticalSpacing))

            VStack(spacing: verticalSpacing) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
                            let day = row * columns + col
                            if day < mappedDays.count {
                                let mappedDay = mappedDays[day]
                                let presentation = your365Presentation?.cellsByDate[mappedDay.date]
                                let isTapDisabled = presentation.map {
                                    $0.state == .future || $0.state == .notTracked
                                } ?? false

                                TappableGridDot(
                                    color: mappedDay.color,
                                    dotSize: dotSize,
                                    hitSize: hitSize,
                                    isDisabled: isTapDisabled
                                ) {
                                    handleDayTap(mappedDay.date)
                                }
                            } else {
                                Color.clear.frame(width: dotSize, height: dotSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
        }
    }

    private static func makeMappedDays(
        calendar: CustomCalendar,
        dates: [Date],
        today: Date,
        your365Presentation: Your365Presentation?
    ) -> [(date: Date, color: Color)] {
        let counts = calendar.entries.values.map { $0.count }
        let scale = precomputeRobustDotScale(for: counts)
        return dates.map {
            let presentation = your365Presentation?.cellsByDate[$0]

            if let presentation {
                return (
                    date: $0,
                    color: colorForYour365Day(
                        presentation,
                        calendar: calendar,
                        today: today,
                        precomputedScale: scale
                    )
                )
            }

            return (
                date: $0,
                color: colorForDay($0, calendar: calendar, today: today, precomputedScale: scale)
            )
        }
    }

    private static func colorForYour365Day(
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
}

private struct TappableGridDot: View {
    let color: Color
    let dotSize: CGFloat
    let hitSize: CGFloat
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        GridDot(color: color, dotSize: dotSize)
            .frame(width: dotSize, height: dotSize)
            .background(
                Color.clear
                    .frame(width: hitSize, height: hitSize)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isDisabled else { return }
                        onTap()
                    }
            )
    }
}
