import SharedModels
import SwiftDate
import SwiftUI

struct GridView: View {
    let calendar: CustomCalendar
    let store: CustomCalendarStore
    let handleDayTap: (Date) -> Void
    let dates: [Date]
    let year: Int

    @Environment(\.colorScheme) var colorScheme
    @State var mappedDays: [(date: Date, color: Color)] = []

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

            VStack(spacing: verticalSpacing) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
                            let day = row * columns + col
                            if day < mappedDays.count {
                                TappableGridDot(
                                    color: mappedDays[day].color,
                                    dotSize: dotSize,
                                    hitSize: hitSize
                                ) {
                                    handleDayTap(mappedDays[day].date)
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
                    let maxCount = getMaxCount(calendar: calendar)
                    mappedDays = dates.map {
                        (date: $0, color: colorForDay($0, calendar: calendar, today: today, maxCount: maxCount))
                    }
                    CacheStore.shared.set(cacheKey, value: mappedDays)
                }
            }
        }
    }

    func updateData() {}

    private var cacheSignature: String {
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        let daySeedKey = dayKey(for: LocalDayCalendar.startOfDay(for: Date()))
        let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
        return "\(calendar.id.uuidString)|\(year)|v\(store.dataVersion)|\(calendar.cadence.rawValue)|\(schemeKey)|\(daySeedKey)|\(timeZoneKey)"
    }

    private var today: Date {
        Date().date
    }
}

private struct TappableGridDot: View {
    let color: Color
    let dotSize: CGFloat
    let hitSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        GridDot(color: color, dotSize: dotSize)
            .frame(width: dotSize, height: dotSize)
            .background(
                Color.clear
                    .frame(width: hitSize, height: hitSize)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
            )
    }
}
