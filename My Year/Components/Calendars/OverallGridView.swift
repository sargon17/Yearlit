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
      let dataVersion = snapshot.dataVersion
      let sig = cacheSignature(dataVersion: dataVersion, isLoading: snapshot.isLoading, year: year)
      let layout = CalendarGridLayout(size: geometry.size, dayCount: mappedDays.count)

      Canvas { context, _ in
        for index in mappedDays.indices {
          let center = layout.center(for: index)
          let rect = CGRect(
            x: center.x - (CalendarGridLayout.dotSize / 2),
            y: center.y - (CalendarGridLayout.dotSize / 2),
            width: CalendarGridLayout.dotSize,
            height: CalendarGridLayout.dotSize
          )
          context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(mappedDays[index].color))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
