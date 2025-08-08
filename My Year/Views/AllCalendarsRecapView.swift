import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct AllCalendarsRecapView: View {
  @ObservedObject private var store: CustomCalendarStore = CustomCalendarStore.shared
  @ObservedObject private var valuationStore: ValuationStore = ValuationStore.shared

  @Environment(\.router) private var router

  @State private var customerInfo: CustomerInfo?
  @State private var isPaywallPresented: Bool = false

  private let today = Date()

  private func isPremium() -> Bool {
    customerInfo?.entitlements["premium"]?.isActive ?? false
  }

  private func percentile(_ values: [Int], p: Double) -> Double {
    let s = values.sorted()
    if s.isEmpty { return 1 }
    let pos = max(0, min(Double(s.count - 1), p * Double(s.count - 1)))
    let lo = Int(floor(pos))
    let hi = Int(ceil(pos))
    if lo == hi { return Double(s[lo]) }
    let w = pos - Double(lo)
    return Double(s[lo]) * (1 - w) + Double(s[hi]) * w
  }

  private func normalizedProgress(for calendar: CustomCalendar, entry: CalendarEntry?) -> Double {
    guard let e = entry else { return 0 }
    switch calendar.trackingType {
    case .binary:
      return e.completed ? 1 : 0
    case .counter:
      let counts = calendar.entries.values.map { $0.count }
      let q = max(1.0, percentile(counts, p: 0.75))
      return min(Double(e.count) / q, 1.0)
    case .multipleDaily:
      let target = max(1, calendar.dailyTarget)
      return min(Double(e.count) / Double(target), 1.0)
    }
  }

  private func isSuccess(for calendar: CustomCalendar, entry: CalendarEntry?) -> Bool {
    guard let e = entry else { return false }
    switch calendar.trackingType {
    case .binary:
      return e.completed
    case .counter:
      return e.count > 0
    case .multipleDaily:
      return e.count >= calendar.dailyTarget
    }
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

    func entry(for calendar: CustomCalendar, _ date: Date) -> CalendarEntry? {
      store.getEntry(calendarId: calendar.id, date: date)
    }

    // Basic aggregate counts
    var totalCount = 0
    var perDayTotal: [Date: Int] = [:]
    for calendar in activeCalendars {
      for entry in calendar.entries.values {
        totalCount += entry.count
        let day = cal.startOfDay(for: entry.date)
        perDayTotal[day, default: 0] += entry.count
      }
    }
    let maxCount = perDayTotal.values.max() ?? 0

    // Day success (any calendar) and normalized intensity (mean z across calendars WITH entries)
    var anySuccessByDay: [Date: Bool] = [:]
    var dayMeanZ: [Date: Double] = [:]
    if let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
      let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))
    {
      var d = startOfYear
      let last = min(endOfYear, todayLocal)
      while d <= last {
        var any = false
        var zAccum = 0.0
        var zDenom = 0.0
        for c in activeCalendars {
          let e = entry(for: c, d)
          if isSuccess(for: c, entry: e) { any = true }
          if e != nil {
            zAccum += normalizedProgress(for: c, entry: e)
            zDenom += 1
          }
        }
        anySuccessByDay[d] = any
        if zDenom > 0 { dayMeanZ[d] = zAccum / zDenom }
        guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
        d = nd
      }
    }
    let activeDays = anySuccessByDay.values.filter { $0 }.count

    // Streaks on any-success series
    var currentStreak = 0
    var longestStreak = 0
    var temp = 0
    let sortedDays = anySuccessByDay.keys.sorted()
    for day in sortedDays {
      if anySuccessByDay[day] == true {
        temp += 1
        longestStreak = max(longestStreak, temp)
      } else {
        temp = 0
      }
    }
    // Current streak from end
    for day in sortedDays.reversed() {
      if anySuccessByDay[day] == true { currentStreak += 1 } else { break }
    }

    // Today count (sum across calendars)
    let todayKeyCount = activeCalendars.reduce(0) { partial, c in
      let e = store.getEntry(calendarId: c.id, date: cal.startOfDay(for: todayLocal))
      return partial + (e?.count ?? 0)
    }

    // 30d completion rate and rolling averages using mean z across calendars
    func lastNDates(_ n: Int) -> [Date] {
      let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(n - 1), to: todayLocal)!)
      return (0..<n).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        .filter { $0 <= todayLocal }
    }
    let d30 = lastNDates(30)
    var succ30 = 0
    var zSum7 = 0.0
    var zSum30 = 0.0
    for (i, d) in d30.enumerated() {
      // any-success
      if anySuccessByDay[d] == true { succ30 += 1 }
      // mean z across calendars
      var zAccum = 0.0
      var zCount = 0.0
      for c in activeCalendars {
        if let e = entry(for: c, d) {
          let z = normalizedProgress(for: c, entry: e)
          zAccum += z
          zCount += 1
        }
      }
      let meanZ = zCount > 0 ? zAccum / zCount : 0
      zSum30 += meanZ
      if i >= d30.count - 7 { zSum7 += meanZ }
    }
    let cr30 = d30.isEmpty ? 0 : Double(succ30) / Double(d30.count)
    let avg7 = d30.isEmpty ? 0 : zSum7 / Double(min(7, d30.count))
    let avg30 = d30.isEmpty ? 0 : zSum30 / Double(d30.count)

    // Best weekday and weekday rates using mean normalized progress per day (only days with entries)
    var wdTotals: [Int: (sumZ: Double, denomDays: Int)] = [:]
    for (day, meanZ) in dayMeanZ {
      let wd = cal.component(.weekday, from: day)
      let cur = wdTotals[wd] ?? (0.0, 0)
      wdTotals[wd] = (cur.sumZ + meanZ, cur.denomDays + 1)
    }
    var weekdayRates: [Int: Double] = [:]
    var bestWD: (day: Int, rate: Double)? = nil
    for (wd, pair) in wdTotals {
      let r = pair.denomDays > 0 ? pair.sumZ / Double(pair.denomDays) : 0
      weekdayRates[wd] = r
      if bestWD == nil || r > bestWD!.rate { bestWD = (wd, r) }
    }

    // Monthly breakdown: average mean normalized progress across days with entries
    var monthly: [Int: Double] = [:]
    for m in 1...12 {
      guard let start = cal.date(from: DateComponents(year: year, month: m, day: 1)) else { continue }
      guard let range = cal.range(of: .day, in: .month, for: start) else { continue }
      let isCurrentMonth =
        (year == cal.component(.year, from: todayLocal) && m == cal.component(.month, from: todayLocal))
      let lastDay = isCurrentMonth ? cal.component(.day, from: todayLocal) : range.count
      if lastDay <= 0 {
        monthly[m] = 0
        continue
      }
      var sumZ = 0.0
      var denomDays = 0
      for day in 1...lastDay {
        if let dt = cal.date(from: DateComponents(year: year, month: m, day: day)), let meanZ = dayMeanZ[dt] {
          sumZ += meanZ
          denomDays += 1
        }
      }
      monthly[m] = denomDays > 0 ? sumZ / Double(denomDays) : 0
    }

    // Weekly volatility of any-success CR (last 12 weeks)
    var weekly: [Double] = []
    var endOfWeek = todayLocal
    for _ in 0..<12 {
      guard let startOfWeek = cal.date(byAdding: .day, value: -6, to: endOfWeek) else { break }
      var succ = 0
      var denom = 0
      var d = startOfWeek
      while d <= endOfWeek {
        succ += (anySuccessByDay[d] == true) ? 1 : 0
        denom += 1
        guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
        d = nd
      }
      weekly.append(denom > 0 ? Double(succ) / Double(denom) : 0)
      guard let prev = cal.date(byAdding: .day, value: -7, to: endOfWeek) else { break }
      endOfWeek = prev
    }
    let volatility: Double = {
      guard !weekly.isEmpty else { return 0 }
      let mean = weekly.reduce(0, +) / Double(weekly.count)
      let variance = weekly.reduce(0) { $0 + pow($1 - mean, 2) } / Double(weekly.count)
      return sqrt(variance)
    }()

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
      monthlyRates: monthly,
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

        CustomSeparator()

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
