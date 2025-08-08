import SharedModels
import SwiftDate
import SwiftUI

struct GridView: View {
  let calendar: CustomCalendar
  let store: CustomCalendarStore
  let valuationStore: ValuationStore
  let handleDayTap: (Date) -> Void

  @Environment(\.colorScheme) var colorScheme

  @Environment(\.dates) var dates
  let today: Date = Date().date
  @State var mappedDays: [(date: Date, color: Color)] = []

  // Cache instance for mappedDays
  private static let mappedDaysCache = DaysCache<String, [(date: Date, color: Color)]>()

  var body: some View {
    // Calendar grid
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 20

      let availableWidth = geometry.size.width - (padding * 2)
      let availableHeight = geometry.size.height - (padding * 2)

      let aspectRatio = availableWidth / availableHeight
      let targetColumns = Int(sqrt(Double(dates.count) * aspectRatio))
      let columns = min(targetColumns, dates.count)
      let rows = Int(ceil(Double(dates.count) / Double(columns)))

      let horizontalSpacing =
        (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
      let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)

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
                .onTapGesture {
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
      .task(
        id: "\(calendar.entries.values.reduce(0) { $0 + $1.count })-\(colorScheme)"
      ) {
        let cacheKey = "\(calendar.name)-\(colorScheme)-\(calendar.entries.values.reduce(0) { $0 + $1.count } )"
        if let cachedMappedDays = Self.mappedDaysCache.get(for: cacheKey) {
          print("🟢 Hitting Cache")
          mappedDays = cachedMappedDays
        } else {
          print("🔴 Missing Cache")
          // Self.mappedDaysCache.clear()  // is that cleaning the cache right?
          mappedDays = dates.map { (date: $0, color: colorForDay($0, calendar: calendar, today: today)) }
          Self.mappedDaysCache.set(mappedDays, for: cacheKey)
        }
      }
      .onChange(of: calendar.entries.values.reduce(0) { $0 + $1.count }) { oldVal, newVal in
        //* removing old cache for entries count as the value could have changed with the same count, the cache retunred the old cached values
        let cacheKey = "\(calendar.name)-\(colorScheme)-\(oldVal)"
        Self.mappedDaysCache.delete(for: cacheKey)
      }
    }
  }
}

// Simple in-memory cache using a dictionary
private class DaysCache<Key: Hashable, Value> {
  private var cache: [Key: Value] = [:]

  func get(for key: Key) -> Value? {
    return cache[key]
  }

  func set(_ value: Value, for key: Key) {
    cache[key] = value
  }

  func delete(for key: Key) {
    let index = cache.firstIndex { $0.key == key }
    guard index != nil else { return }

    cache.remove(at: index!)
  }

  func clear() {
    cache.removeAll()
  }
}
