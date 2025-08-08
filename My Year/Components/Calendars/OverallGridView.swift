import SharedModels
import SwiftDate
import SwiftUI

struct OverallGridView: View {
  let accentColor: Color
  let store: CustomCalendarStore

  @Environment(\.dates) var dates
  let today: Date = DateInRegion(region: .current).date
  @State private var mappedDays: [(date: Date, color: Color)] = []

  private static let mappedDaysCache = DaysCache<String, [(date: Date, color: Color)]>()

  var body: some View {
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 20

      let availableWidth = geometry.size.width - (padding * 2)
      let availableHeight = geometry.size.height - (padding * 2)

      let aspectRatio = availableWidth / availableHeight
      let targetColumns = Int(sqrt(Double(365) * aspectRatio))
      let columns = min(targetColumns, 365)
      let rows = Int(ceil(Double(365) / Double(columns)))

      let horizontalSpacing =
        (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1))
      let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1))

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
          mappedDays = dates.map { (date: $0, color: overallColorForDay($0)) }
          Self.mappedDaysCache.set(mappedDays, for: cacheKey)
        }
      }
    }
  }

  private func cacheSignature() -> String {
    let total = store.calendars.reduce(0) { sum, cal in
      sum + cal.entries.values.reduce(0) { $0 + $1.count }
    }
    return "overall-grid-\(total)"
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
    if day > today { return Color("dot-inactive") }

    // If no data across all calendars for this day, use a very light tint to indicate no data
    if !dataPresent(on: day) {
      return Color("dot-inactive").opacity(0.15)
    }

    // Average normalized progress across calendars for shading
    var zSum: Double = 0
    var denom: Double = 0
    for cal in store.calendars {
      let entry = store.getEntry(calendarId: cal.id, date: day)
      zSum += normalizedProgress(calendar: cal, entry: entry)
      denom += 1
    }
    let z = denom > 0 ? zSum / denom : 0
    if z <= 0 { return Color("dot-active").opacity(0.25) }
    let opacity = min(1, max(0.2, z))
    return accentColor.opacity(opacity)
  }

  private func normalizedProgress(calendar: CustomCalendar, entry: CalendarEntry?) -> Double {
    guard let entry = entry else { return 0 }
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? 1 : 0
    case .counter:
      let counts = calendar.entries.values.map { $0.count }
      let q = max(1, percentile(counts, p: 0.75))
      return min(Double(entry.count) / Double(q), 1.0)
    case .multipleDaily:
      let t = max(1, calendar.dailyTarget)
      return min(Double(entry.count) / Double(t), 1.0)
    }
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
  func get(for key: Key) -> Value? { cache[key] }
  func set(_ value: Value, for key: Key) { cache[key] = value }
  func clear() { cache.removeAll() }
}
