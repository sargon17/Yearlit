import SharedModels
import SwiftDate
import SwiftUI

struct GridView: View {
  let calendar: CustomCalendar
  let store: CustomCalendarStore
  let valuationStore: ValuationStore
  let handleDayTap: (Int) -> Void

  @Environment(\.dates) var dates
  let today: Date = DateInRegion(region: .current).date
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
      let targetColumns = Int(sqrt(Double(365) * aspectRatio))
      let columns = min(targetColumns, 365)
      let rows = Int(ceil(Double(365) / Double(columns)))

      let horizontalSpacing =
        (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
      let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)

      //       public func dateForDay(_ day: Int) -> Date {
      //   let calendar = Calendar.current
      //   let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
      //   return calendar.date(byAdding: .day, value: day, to: startOfYear)!
      // }

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
                  handleDayTap(day)
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
        id: calendar.entries.values.reduce(0) { $0 + $1.count }
      ) {
        let cacheKey = "\(calendar.name)-\(calendar.entries.values.reduce(0) { $0 + $1.count } )"
        if let cachedMappedDays = Self.mappedDaysCache.get(for: cacheKey) {
          mappedDays = cachedMappedDays
        } else {
          mappedDays = dates.map { (date: $0, color: colorForDay($0, calendar: calendar, today: today)) }
          Self.mappedDaysCache.set(mappedDays, for: cacheKey)
        }
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

  func clear() {
    cache.removeAll()
  }
}
