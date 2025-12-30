import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct OverallGridView: View {
  let accentColor: Color
  let store: CustomCalendarStore

  @Environment(\.dates) var dates
  @Environment(\.colorScheme) var colorScheme
  let today: Date = DateInRegion(region: .current).date
  @State private var mappedDays: [(date: Date, color: Color)] = []
  @State private var counterPct75: [UUID: Double] = [:]
  @State private var didUseDiskGridCache: Bool = false

  private static let mappedDaysCache = DaysCache<String, [(date: Date, color: Color)]>()

  var body: some View {
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 20

      let availableWidth = max(0, geometry.size.width - (padding * 2))
      let availableHeight = max(1, geometry.size.height - (padding * 2))  // avoid /0

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
      let sig = cacheSignature(dataVersion: dataVersion)
      let daySeedKey = dayKey(for: Calendar.current.startOfDay(for: today))
      let year = Calendar.current.component(.year, from: today)
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
      .padding(.horizontal)
      .task(id: sig) {
        if didUseDiskGridCache { return }
        if OverviewGridCache.load(year: year, daySeedKey: daySeedKey) != nil {
          didUseDiskGridCache = true
          return
        }
        if store.isLoading { return }
        guard store.dataVersion == dataVersion else { return }
        let cacheKey = sig
        if let cached = Self.mappedDaysCache.get(for: cacheKey) {
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
              })

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
            mappedDays = result.1.map { (date, z) in
              let inactiveColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
              let activeColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)
              if date > today {  // future days stay inactive
                return (date: date, color: inactiveColor)
              }
              if z <= 0 {  // no data or zero progress → neutral active shade (not accent)
                return (date: date, color: activeColor)
              }
              let opacity = min(1, max(0.2, z))
              return (date: date, color: accent.opacity(opacity))
            }
            Self.mappedDaysCache.set(mappedDays, for: cacheKey)
            let zByDay = Dictionary(uniqueKeysWithValues: result.1.map { (date, z) in
              (dayKey(for: date), z)
            })
            OverviewGridCache.save(zByDay: zByDay, year: year, daySeedKey: daySeedKey)
          }
        }
      }
      .task(id: daySeedKey) {
        guard mappedDays.isEmpty else { return }
        guard let zByDay = OverviewGridCache.load(year: year, daySeedKey: daySeedKey) else { return }
        didUseDiskGridCache = true
        let inactiveColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
        let activeColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)
        let cachedMappedDays = dates.map { day -> (date: Date, color: Color) in
          if day > today { return (day, inactiveColor) }
          let z = zByDay[dayKey(for: day)] ?? 0
          if z <= 0 { return (day, activeColor) }
          let opacity = min(1, max(0.2, z))
          return (day, accentColor.opacity(opacity))
        }
        mappedDays = cachedMappedDays
      }
    }
  }

  private func cacheSignature(dataVersion: Int) -> String {
    let schemeKey = colorScheme == .dark ? "dark" : "light"
    return "overall-grid-\(dataVersion)-\(schemeKey)"
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
    let inactiveColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.02)
    let activeColor = GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.08)

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

private class DaysCache<Key: Hashable, Value> {
  private var cache: [Key: Value] = [:]
  private let queue = DispatchQueue(label: "OverallGridView.DaysCache", attributes: .concurrent)

  func get(for key: Key) -> Value? {
    queue.sync { cache[key] }
  }

  func set(_ value: Value, for key: Key) {
    queue.sync(flags: .barrier) { cache[key] = value }
  }

  func clear() {
    queue.sync(flags: .barrier) { cache.removeAll() }
  }
}
