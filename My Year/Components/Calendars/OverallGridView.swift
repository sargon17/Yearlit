import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct OverallGridView: View {
  let accentColor: Color
  let store: CustomCalendarStore
  let year: Int

  @Environment(\.colorScheme) var colorScheme
  @AppStorage(AppStorageKeys.gridVisualizationStyle, store: TimelinePreferenceStore.appGroupDefaults)
  private var visualizationStyle: GridVisualizationStyle = .dot
  let today: Date = DateInRegion(region: .current).date
  @State private var mappedDays: [GridDay] = []

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
          let day = mappedDays[index]
          let center = layout.center(for: index)
          let markSize = visualizationStyle.markSize(base: CalendarGridLayout.dotSize, fillRatio: day.fillRatio)
          let rect = CGRect(
            x: center.x - (markSize / 2),
            y: center.y - (markSize / 2),
            width: markSize,
            height: markSize
          )
          context.fill(visualizationStyle.path(in: rect), with: .color(day.color))
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

  private func mappedDays(from zByDay: [Double]) -> [GridDay] {
    let futureColor = futureDayColor()
    let todayColor = activeDayColor()
    let missedColor = missedDayColor()
    let todayBucket = LocalDayCalendar.startOfDay(for: today)
    return zip(dates, zByDay).map { day, z -> GridDay in
      let dayBucket = day  // dates from getYearDatesArray are pre-bucketed to midnight
      if dayBucket > todayBucket { return GridDay(date: day, color: futureColor, fillRatio: 0) }
      if z <= 0 {
        return GridDay(date: day, color: dayBucket == todayBucket ? todayColor : missedColor, fillRatio: 0)
      }
      let intensity = min(1, max(0.2, z))
      return GridDay(date: day, color: accentColor.opacity(intensity), fillRatio: intensity)
    }
  }
}
