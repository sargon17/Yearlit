import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct OverallGridView: View {
    let accentColor: Color
    let store: CustomCalendarStore
    let dates: [Date]
    let year: Int

    @Environment(\.colorScheme) var colorScheme
    let today: Date = DateInRegion(region: .current).date
    @State private var mappedDays: [(date: Date, color: Color)] = []
    @State private var didUseDiskGridCache: Bool = false

    var body: some View {
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
            let dataVersion = store.dataVersion
            let sig = cacheSignature(dataVersion: dataVersion, year: year)
            let daySeedKey = dayKey(for: Calendar.current.startOfDay(for: today))
            let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
            let cacheKey = CacheKey(scope: .overviewGridMappedDays, identifier: sig)
            let diskKey = CacheKey(
                scope: .overviewGridZByDay,
                identifier: "v2|\(year)|\(daySeedKey)|\(timeZoneKey)|v\(dataVersion)"
            )
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
            .onChange(of: sig) { _, _ in
                didUseDiskGridCache = false
            }
            .task(id: sig) {
                if didUseDiskGridCache { return }
                if let zByDay: [Double] = CacheStore.shared.loadDisk(diskKey), zByDay.count == dates.count {
                    didUseDiskGridCache = true
                    mappedDays = mappedDays(from: zByDay)
                    return
                }
                if store.isLoading { return }
                guard store.dataVersion == dataVersion else { return }
                if let cached: [(date: Date, color: Color)] = CacheStore.shared.get(cacheKey) {
                    await MainActor.run { mappedDays = cached }
                } else {
                    // Snapshot minimal values we’ll need across threads
                    let calendars = store.calendars
                    let datesArray = Array(dates)
                    let todayLocal = today
                    let accent = accentColor
                    let entriesByCalendarByBucket = buildEntriesByCalendarByBucket(calendars: calendars)

                    let result = await Task.detached(priority: .userInitiated) { () -> [(Date, Double)] in
                        let pct75 = counterPercentile75ByCalendar(calendars: calendars)

                        let shades: [(Date, Double)] = datesArray.map { day in
                            if day > todayLocal { return (day, 0.0) }
                            var zSum: Double = 0
                            var denom: Double = 0
                            for cal in calendars {
                                let entry = entry(for: cal, date: day, entriesByCalendarByBucket: entriesByCalendarByBucket)
                                zSum += normalizedProgress(for: cal, entry: entry, q75: pct75[cal.id])
                                denom += 1
                            }
                            let z = denom > 0 ? zSum / denom : 0
                            return (day, z)
                        }

                        return shades
                    }.value

                    await MainActor.run {
                        mappedDays = result.map { date, z in
                            let inactiveColor = inactiveDayColor()
                            let activeColor = activeDayColor()
                            if date > today { // future days stay inactive
                                return (date: date, color: inactiveColor)
                            }
                            if z <= 0 { // no data or zero progress → neutral active shade (not accent)
                                return (date: date, color: activeColor)
                            }
                            let opacity = min(1, max(0.2, z))
                            return (date: date, color: accent.opacity(opacity))
                        }
                        CacheStore.shared.set(cacheKey, value: mappedDays)
                        let zByDay = result.map(\.1)
                        CacheStore.shared.saveDisk(diskKey, value: zByDay)
                    }
                }
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
