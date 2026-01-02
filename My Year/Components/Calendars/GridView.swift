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

  var body: some View {
    // Calendar grid
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 20

      let availableWidth = geometry.size.width - (padding * 2)
      let availableHeight = geometry.size.height - (padding * 2)

      let aspectRatio = availableWidth / availableHeight
      let targetColumns = Int(sqrt(Double(dates.count) * aspectRatio))
      let columns = max(min(targetColumns, dates.count), 1)
      let rows = max(Int(ceil(Double(dates.count) / Double(columns))), 1)

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
        let maxCount = getMaxCount(calendar: calendar)
        let entriesSignature = calendar.entries.values.reduce(0) { $0 + $1.count }
        let cacheKey = CacheKey(
          scope: .calendarGridMappedDays,
          identifier: "\(calendar.name)-\(colorScheme)-\(entriesSignature)"
        )
        if let cachedMappedDays: [(date: Date, color: Color)] = CacheStore.shared.get(cacheKey) {
          // print("🟢 Hitting Cache")
          mappedDays = cachedMappedDays
        } else {
          // print("🔴 Missing Cache")
          CacheStore.shared.removeMatching(scope: .calendarGridMappedDays) { identifier in
            identifier.contains(calendar.name)
          }
          mappedDays = dates.map {
            (date: $0, color: colorForDay($0, calendar: calendar, today: today, maxCount: maxCount))
          }
          CacheStore.shared.set(cacheKey, value: mappedDays)
        }
      }
      .onChange(of: calendar.entries.values.reduce(0) { $0 + $1.count }) { oldVal, _ in
        // * removing old cache for entries count as the value could have changed with the same count, the cache retunred the old cached values
        let cacheKey = CacheKey(
          scope: .calendarGridMappedDays,
          identifier: "\(calendar.name)-\(colorScheme)-\(oldVal)"
        )
        CacheStore.shared.remove(cacheKey)
      }
    }
  }

  func updateData() {}
}
