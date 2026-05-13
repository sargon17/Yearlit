import SharedModels
import SwiftDate
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
    let store: CustomCalendarStore
    let handleDayTap: (Date) -> Void
    let dates: [Date]
    let year: Int
    let your365Presentation: Your365Presentation?

    @Environment(\.colorScheme) var colorScheme
    @State var mappedDays: [(date: Date, color: Color)]

    init(
        calendar: CustomCalendar,
        store: CustomCalendarStore,
        handleDayTap: @escaping (Date) -> Void,
        dates: [Date],
        year: Int,
        your365Presentation: Your365Presentation?
    ) {
        self.calendar = calendar
        self.store = store
        self.handleDayTap = handleDayTap
        self.dates = dates
        self.year = year
        self.your365Presentation = your365Presentation
        _mappedDays = State(
            initialValue: Self.makeMappedDays(
                calendar: calendar,
                dates: dates,
                today: Date().date,
                your365Presentation: your365Presentation
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let padding: CGFloat = 20

            let availableWidth = max(0, geometry.size.width - (padding * 2))
            let availableHeight = max(1, geometry.size.height - (padding * 2))

            let aspectRatio = max(0.001, availableWidth / availableHeight)
            let targetColumns = Int(sqrt(Double(dates.count) * aspectRatio))
            let columns = max(min(targetColumns, dates.count), 1)
            let rows = max(Int(ceil(Double(dates.count) / Double(columns))), 1)

            let horizontalSpacing =
                max(0, (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
            let verticalSpacing =
                max(0, (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
            let hitSize = dotSize + max(0, min(horizontalSpacing, verticalSpacing))
            let displayMappedDays = mappedDays.count == dates.count
                ? mappedDays
                : Self.makeMappedDays(
                    calendar: calendar,
                    dates: dates,
                    today: today,
                    your365Presentation: your365Presentation
                )

            VStack(spacing: verticalSpacing) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
                            let day = row * columns + col
                            if day < displayMappedDays.count {
                                let mappedDay = displayMappedDays[day]
                                let presentation = your365Presentation?.cellsByDate[mappedDay.date]
                                let isTapDisabled = presentation.map { $0.state == .future || $0.state == .notTracked } ?? false

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
            .task(id: cacheSignature) {
                let cachePrefix = "\(calendar.id.uuidString)|\(year)|"
                let cacheKey = CacheKey(scope: .calendarGridMappedDays, identifier: cacheSignature)
                CacheStore.shared.removeMatching(scope: .calendarGridMappedDays) { identifier in
                    identifier.hasPrefix(cachePrefix) && identifier != cacheSignature
                }

                if let cachedMappedDays: [(date: Date, color: Color)] = CacheStore.shared.get(cacheKey) {
                    mappedDays = cachedMappedDays
                } else {
                    mappedDays = Self.makeMappedDays(
                        calendar: calendar,
                        dates: dates,
                        today: today,
                        your365Presentation: your365Presentation
                    )
                    CacheStore.shared.set(cacheKey, value: mappedDays)
                }
            }
        }
    }

    func updateData() {}

    private var cacheSignature: String {
        let snapshot = store.snapshot
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        let daySeedKey = dayKey(for: LocalDayCalendar.startOfDay(for: Date()))
        let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
        let presentationKey = your365Presentation.map {
            "y365:\($0.snapshot.trackingStartedAt.timeIntervalSince1970):\($0.snapshot.cells.count)"
        } ?? "y365:none"
        return "\(calendar.id.uuidString)|\(year)|v\(snapshot.dataVersion)|\(calendar.cadence.rawValue)|\(schemeKey)|\(daySeedKey)|\(timeZoneKey)|\(presentationKey)"
    }

    private var today: Date {
        Date().date
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
                return (date: $0, color: colorForYour365Day(presentation, calendar: calendar, today: today, precomputedScale: scale))
            }

            return (date: $0, color: colorForDay($0, calendar: calendar, today: today, precomputedScale: scale))
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
            return colorForDay(cell.date, calendar: calendar, today: today, precomputedScale: precomputedScale)
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
