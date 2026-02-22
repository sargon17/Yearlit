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
    @State private var counterPct75: [UUID: Double] = [:]
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
            let cacheKey = CacheKey(scope: .overviewGridMappedDays, identifier: sig)
            let diskKey = CacheKey(
                scope: .overviewGridZByDay,
                identifier: "\(year)|\(daySeedKey)|v\(dataVersion)"
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
                if let zByDay: [String: Double] = CacheStore.shared.loadDisk(diskKey) {
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
                    let entriesByCalendar = Dictionary(uniqueKeysWithValues: calendars.map { ($0.id, $0.entries) })

                    // Heavy work off-main: compute q75 and numeric shades only
                    let result = await Task.detached(priority: .userInitiated) { () -> ([UUID: Double], [(Date, Double)]) in
                        let pct75: [UUID: Double] = Dictionary(
                            uniqueKeysWithValues: calendars.map { cal in
                                if cal.trackingType == .counter {
                                    let counts = cal.entries.values.map { $0.count }
                                    let q = max(1, Int(percentile(counts, p: 0.75)))
                                    return (cal.id, Double(q))
                                } else {
                                    return (cal.id, 1.0)
                                }
                            }
                        )

                        let shades: [(Date, Double)] = datesArray.map { day in
                            if day > todayLocal { return (day, 0.0) }
                            let key = dayKey(for: day)
                            var zSum: Double = 0
                            var denom: Double = 0
                            for cal in calendars {
                                let entry = entriesByCalendar[cal.id]?[key]
                                zSum += normalizedProgress(for: cal, entry: entry, q75: pct75[cal.id])
                                denom += 1
                            }
                            let z = denom > 0 ? zSum / denom : 0
                            return (day, z)
                        }

                        return (pct75, shades)
                    }.value

                    await MainActor.run {
                        counterPct75 = result.0
                        mappedDays = result.1.map { date, z in
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
                        let zByDay = Dictionary(
                            uniqueKeysWithValues: result.1.map { date, z in
                                (dayKey(for: date), z)
                            }
                        )
                        CacheStore.shared.saveDisk(diskKey, value: zByDay)
                    }
                }
            }
        }
    }

    private func cacheSignature(dataVersion: Int, year: Int) -> String {
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        return "overall-grid-\(year)-\(dataVersion)-\(schemeKey)"
    }

    private func mappedDays(from zByDay: [String: Double]) -> [(date: Date, color: Color)] {
        let inactiveColor = inactiveDayColor()
        let activeColor = activeDayColor()
        return dates.map { day -> (date: Date, color: Color) in
            if day > today { return (day, inactiveColor) }
            let z = zByDay[dayKey(for: day)] ?? 0
            if z <= 0 { return (day, activeColor) }
            let opacity = min(1, max(0.2, z))
            return (day, accentColor.opacity(opacity))
        }
    }

    private func dataPresent(on day: Date) -> Bool {
        for cal in store.calendars {
            if store.getEntry(calendarId: cal.id, date: day) != nil {
                return true
            }
        }
        return false
    }

    private func overallColorForDay(_ day: Date) -> Color {
        let inactiveColor = inactiveDayColor()
        let activeColor = activeDayColor()

        if day > today { return inactiveColor }

        // Average normalized progress across calendars for shading
        var zSum: Double = 0
        var denom: Double = 0
        for cal in store.calendars {
            let entry = store.getEntry(calendarId: cal.id, date: day)
            zSum += normalizedProgress(for: cal, entry: entry, q75: counterPct75[cal.id])
            denom += 1
        }
        let z = denom > 0 ? zSum / denom : 0
        if z <= 0 { return activeColor }
        let opacity = min(1, max(0.2, z))
        return accentColor.opacity(opacity)
    }
}
