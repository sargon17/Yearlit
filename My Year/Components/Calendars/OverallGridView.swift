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

        let dotSize: CGFloat = 10
        let padding: CGFloat = 20
        let dataVersion = snapshot.dataVersion
        let sig = "\(cacheSignature(dataVersion: dataVersion, year: year))|loading:\(snapshot.isLoading)"

        DotGrid(
            items: mappedDays,
            dotSize: dotSize,
            padding: padding,
            dot: { day in
                GridDot(color: day.color, dotSize: dotSize)
            },
            onTap: nil
        )
        .task(id: sig) {
            guard !snapshot.isLoading else {
                mappedDays = []
                return
            }
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

    private func cacheSignature(dataVersion: Int, year: Int) -> String {
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        let daySeedKey = dayKey(for: LocalDayCalendar.startOfDay(for: today))
        let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
        return "overall-grid|v2|\(year)|\(dataVersion)|\(schemeKey)|\(daySeedKey)|\(timeZoneKey)"
    }

    private func mappedDays(from zByDay: [Double]) -> [(date: Date, color: Color)] {
        let inactiveColor = inactiveDayColor()
        let activeColor = activeDayColor()
        return zip(dates, zByDay).map { day, z -> (date: Date, color: Color) in
            if day > today { return (day, inactiveColor) }
            if z <= 0 { return (day, activeColor) }
            let opacity = min(1, max(0.2, z))
            return (day, accentColor.opacity(opacity))
        }
    }
}
