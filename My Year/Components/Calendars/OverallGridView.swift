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
      .task(id: cacheSignature()) {
        let cacheKey = cacheSignature()
        if let cached = Self.mappedDaysCache.get(for: cacheKey) {
          mappedDays = cached
        } else {
          // Precompute 75th-percentile counts per calendar (cache once per recompute)
          let pct75 = Dictionary(
            uniqueKeysWithValues: store.calendars.map { cal in
              let counts = cal.entries.values.map { $0.count }
              let q = max(1, percentile(counts, p: 0.75))
              return (cal.id, Double(q))
            })
          counterPct75 = pct75

          mappedDays = dates.map { (date: $0, color: overallColorForDay($0)) }
          Self.mappedDaysCache.set(mappedDays, for: cacheKey)
        }
      }
    }
  }

  private func cacheSignature() -> String {
    var hasher = Hasher()

    // Sort calendars to ensure deterministic order
    let calendars = store.calendars.sorted { $0.id.uuidString < $1.id.uuidString }
    hasher.combine(calendars.count)

    for cal in calendars {
      hasher.combine(cal.id)
      hasher.combine(cal.dailyTarget)
      hasher.combine(cal.trackingType)

      // Sort entries by date for deterministic order
      let entries = cal.entries.sorted { $0.key < $1.key }
      hasher.combine(entries.count)

      for (date, e) in entries {
        hasher.combine(date)
        hasher.combine(e.count)
        hasher.combine(e.completed)
      }
    }

    // Include UI-related factors that affect colors so cache invalidates on appearance changes
    hasher.combine(colorScheme == .dark ? "dark" : "light")

    return "overall-grid-\(hasher.finalize())"
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

  private func percentile(_ values: [Int], p: Double) -> Int {
    let sorted = values.sorted()
    if sorted.isEmpty { return 1 }
    let pos = max(0, min(Double(sorted.count - 1), p * Double(sorted.count - 1)))
    let lower = Int(floor(pos))
    let upper = Int(ceil(pos))
    if lower == upper { return sorted[lower] }
    let weight = pos - Double(lower)
    let interpolated = Double(sorted[lower]) * (1 - weight) + Double(sorted[upper]) * weight
    return max(1, Int(interpolated.rounded()))
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
