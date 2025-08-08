import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct AllCalendarsRecapView: View {
  @ObservedObject private var store: CustomCalendarStore = .shared
  @ObservedObject private var valuationStore: ValuationStore = .shared

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var colorScheme

  @State private var customerInfo: CustomerInfo?
  @State private var isPaywallPresented: Bool = false

  private let today = Date()

  private func isPremium() -> Bool {
    customerInfo?.entitlements["premium"]?.isActive ?? false
  }
  private struct StatsBundle {
    let basic: CalendarStats
    let completionRate30d: Double
    let bestWeekday: Int?
    let weekdayRates: [Int: Double]
    let monthlyRates: [Int: Double]
    let rolling7d: Double
    let rolling30d: Double
    let volatilityStd: Double
    let todaysCount: Int
  }

  private class StatsCache {
    private var cache: [String: StatsBundle] = [:]
    func get(_ key: String) -> StatsBundle? { cache[key] }
    func set(_ key: String, value: StatsBundle) { cache[key] = value }
  }

  private static let statsCache = StatsCache()

  private func makeCacheKey() -> String {
    let year = valuationStore.selectedYear
    let calendarsSignature = store.calendars
      .sorted { $0.id.uuidString < $1.id.uuidString }
      .map { calendar in
        let entriesSig = calendar.entries
          .sorted { $0.key < $1.key }
          .map { "\($0.key):\($0.value.count):\($0.value.completed ? 1 : 0)" }
          .joined(separator: ",")
        return "\(calendar.id.uuidString)|\(entriesSig)"
      }
      .joined(separator: ";")
    return "overall|\(year)|\(calendarsSignature)"
  }

  private func computeOverallStats() -> StatsBundle {
    let key = makeCacheKey()
    if let cached = Self.statsCache.get(key) { return cached }

    let cal = Calendar.current
    let year = valuationStore.selectedYear
    let activeCalendars = store.calendars
    let todayLocal = today

    let (totalCount, perDayTotal) = aggregateCounts(cal: cal, calendars: activeCalendars)
    let maxCount = perDayTotal.values.max() ?? 0

    let (anySuccessByDay, dayMeanZ) = buildDailyMaps(
      cal: cal,
      year: year,
      todayLocal: todayLocal,
      calendars: activeCalendars,
      store: store
    )

    let activeDays = anySuccessByDay.values.filter { $0 }.count
    let (longestStreak, currentStreak) = computeStreaks(anySuccessByDay)

    let todayKeyCount = computeTodayKeyCount(
      cal: cal, todayLocal: todayLocal, calendars: activeCalendars, store: store
    )

    let (cr30, avg7, avg30) = computeRollingStats(
      cal: cal,
      todayLocal: todayLocal,
      calendars: activeCalendars,
      anySuccessByDay: anySuccessByDay,
      store: store
    )

    let (weekdayRates, bestWD) = computeWeekdayRates(cal: cal, dayMeanZ: dayMeanZ)

    let monthlyRates = computeMonthlyRates(
      cal: cal, year: year, todayLocal: todayLocal, dayMeanZ: dayMeanZ
    )

    let volatility = computeWeeklyVolatility(
      cal: cal, todayLocal: todayLocal, anySuccessByDay: anySuccessByDay
    )

    let basic = CalendarStats(
      activeDays: activeDays,
      totalCount: totalCount,
      maxCount: maxCount,
      longestStreak: longestStreak,
      currentStreak: currentStreak
    )

    let bundle = StatsBundle(
      basic: basic,
      completionRate30d: cr30,
      bestWeekday: bestWD?.day,
      weekdayRates: weekdayRates,
      monthlyRates: monthlyRates,
      rolling7d: avg7,
      rolling30d: avg30,
      volatilityStd: volatility,
      todaysCount: todayKeyCount
    )

    Self.statsCache.set(key, value: bundle)
    return bundle
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Overview")
                  .font(.system(size: 36, design: .monospaced))
                  .lineLimit(2)
                  .minimumScaleFactor(0.5)
                  .foregroundColor(Color("text-primary"))
                  .fontWeight(.black)
                  .padding(.top)
                Spacer()
              }
              HStack(spacing: 4) {
                Button(action: {}) {
                  Text("\(valuationStore.year.description)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                }
              }
            }
          }
          .padding(.horizontal)
          .padding(.top, 10)
          CustomSeparator()
        }

        let bundle = computeOverallStats()

        OverallGridView(
          accentColor: Color("qs-emerald"),
          store: store
        )
        .frame(height: UIScreen.main.bounds.height * 0.55)

        CalendarStatisticsView(
          stats: bundle.basic,
          accentColor: Color("qs-emerald"),
          todaysCount: bundle.todaysCount,
          unit: nil,
          currencySymbol: nil,
          completionRateLast30d: bundle.completionRate30d,
          bestWeekday: bundle.bestWeekday,
          weekdayRates: bundle.weekdayRates,
          monthlyRates: bundle.monthlyRates,
          rolling7d: bundle.rolling7d,
          rolling30d: bundle.rolling30d,
          volatilityStdDev: bundle.volatilityStd,
          isPremium: isPremium(),
          onUpgrade: { isPaywallPresented = true }
        )
        .id(colorScheme)
        .padding(.top, 20)

        CustomSeparator()

        VStack(spacing: 0) {
          Text("Thank you for your support!")
          Spacer()
          HStack(spacing: 4) {
            Text("Mykhaylo Tymofyeyev")
            Text("•")
            Text("[@tymofyeyev_m](https://x.com/tymofyeyev_m)")
              .foregroundColor(Color("qs-emerald"))
          }
          .foregroundColor(Color("text-tertiary"))
        }
        .padding(.horizontal)
        .font(.system(size: 9, design: .monospaced))
        .foregroundColor(Color("text-tertiary").opacity(0.5))
        .multilineTextAlignment(.center)
        .padding(.bottom, 40)
      }
    }
    .scrollIndicators(.hidden)
    .background(Color("surface-muted"))
    .sheet(isPresented: $isPaywallPresented) {
      PaywallView()
    }
    .onAppear {
      Purchases.shared.getCustomerInfo { info, _ in
        self.customerInfo = info
      }
    }
  }
}

#Preview {
  AllCalendarsRecapView()
}
