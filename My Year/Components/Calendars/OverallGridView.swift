import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct OverallGridView: View {
    let accentColor: Color
    let store: CustomCalendarStore
    let year: Int

    @Environment(\.colorScheme) var colorScheme
    let today: Date = DateInRegion(region: .current).date
    @State private var mappedDays: [(date: Date, color: Color)] = []

    private var dates: [Date] {
        getYearDatesArray(for: year)
    }

    var body: some View {
        let snapshot = store.snapshot

        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let padding: CGFloat = 20

            let availableWidth = max(0, geometry.size.width - (padding * 2))
            let availableHeight = max(1, geometry.size.height - (padding * 2)) // avoid /0

            let aspectRatio = max(0.001, availableWidth / availableHeight)
            let targetColumns = max(1, min(365, Int(sqrt(365.0 * aspectRatio))))
            let columns = max(1, min(targetColumns, 365))
            let rows = max(1, Int(ceil(365.0 / Double(columns))))

            let horizontalSpacing = max(
                0,
                (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1))
            )
            let verticalSpacing = max(
                0,
                (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1))
            )
            let dataVersion = snapshot.dataVersion
            let sig = cacheSignature(dataVersion: dataVersion, isLoading: snapshot.isLoading, year: year)
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
            .padding(.horizontal)
            .task(id: sig) {
                if snapshot.isLoading { return }
                guard snapshot.dataVersion == dataVersion else { return }
                if let derived = await OverviewDerivedSnapshotService.shared.snapshot(
                    storeSnapshot: snapshot,
                    year: year,
                    today: today
                ) {
                    mappedDays = mappedDays(from: derived.zByDay)
                }
            }
        }
    }

    private func cacheSignature(dataVersion: Int, isLoading: Bool, year: Int) -> String {
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        let daySeedKey = dayKey(for: LocalDayCalendar.startOfDay(for: today))
        let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
        let hydrationKey = isLoading ? "loading" : "hydrated"
        return [
            "overall-grid",
            "v2",
            "\(year)",
            "\(dataVersion)",
            hydrationKey,
            schemeKey,
            daySeedKey,
            timeZoneKey
        ].joined(separator: "|")
    }

    private func mappedDays(from zByDay: [Double]) -> [(date: Date, color: Color)] {
        let futureColor = futureDayColor()
        let todayColor = activeDayColor()
        let missedColor = missedDayColor()
        let todayBucket = LocalDayCalendar.startOfDay(for: today)
        return zip(dates, zByDay).map { day, z -> (date: Date, color: Color) in
            let dayBucket = day  // dates from getYearDatesArray are pre-bucketed to midnight
            if dayBucket > todayBucket { return (day, futureColor) }
            if z <= 0 { return (day, dayBucket == todayBucket ? todayColor : missedColor) }
            let opacity = min(1, max(0.2, z))
            return (day, accentColor.opacity(opacity))
        }
    }
}
