import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting
import UserNotifications
import WidgetKit

enum SelectedDate: Equatable, Identifiable {
  case none
  case selected(Date)

  var id: Date? {
    switch self {
    case .none:
      return nil
    case .selected(let date):
      return date
    }
  }

  var date: Date? {
    switch self {
    case .none:
      return nil
    case .selected(let date):
      return date
    }
  }

  var isPresented: Bool {
    if case .selected = self {
      return true
    }
    return false
  }
}

struct CustomCalendarView: View {

  let calendar: CustomCalendar
  @StateObject private var store: CustomCalendarStore = CustomCalendarStore.shared
  @ObservedObject private var valuationStore: ValuationStore = ValuationStore.shared

  @AppStorage("runtimeDebugEnabled") private var runtimeDebugEnabled: Bool = false
  @AppStorage("wandFillForce") private var wandFillForce: Double = 0.5

  private let today = Date()

  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?
  @State private var customerInfo: CustomerInfo?
  @State private var isPaywallPresented: Bool = false

  @Environment(\.router) private var router

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func fillRandomEntries() {
    // TODO: Implement clearEntries(calendarId:) in CustomCalendarStore to enable clearing before filling.
    store.clearEntries(calendarId: self.calendar.id)

    let calendar = Calendar.current
    let startOfYear = calendar.date(
      from: DateComponents(year: valuationStore.selectedYear, month: 1, day: 1))!

    for day in 0..<valuationStore.currentDayNumber {
      let date = calendar.date(byAdding: .day, value: day, to: startOfYear)!

      if date <= today && Double.random(in: 0.0...1.0) < wandFillForce {
        switch self.calendar.trackingType {
        case .binary:
          let entry = CalendarEntry(date: date, count: 1, completed: true)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .counter:
          let count = Int.random(in: 1...5)
          let entry = CalendarEntry(date: date, count: count, completed: count > 0)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .multipleDaily:
          let count = Int.random(in: 1...self.calendar.dailyTarget)
          let entry = CalendarEntry(
            date: date, count: count, completed: count >= self.calendar.dailyTarget)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        }
      }
    }
  }

  private func handleDayTap(_ date: Date) {
    print(date)
    guard !date.isInFuture else { return }

    if calendar.trackingType != .binary {
      router.showScreen(
        .sheetConfig(config: shortSheetConfig)
      ) { _ in
        DayEntryEditSheet(
          calendar: calendar,
          date: date,
          store: store
        )
      }
    } else if calendar.trackingType == .binary {
      _ = toggleBinaryEntry(calendarId: calendar.id, date: date, calendarStore: store)
    }
    Task {
      await hapticFeedback()
    }
  }

  private func getStats() -> CalendarStats {
    let activeDays = calendar.entries.values.filter { entry in
      switch calendar.trackingType {
      case .binary:
        return entry.completed
      case .counter, .multipleDaily:
        return entry.count > 0
      }
    }.count

    let totalCount = calendar.entries.values.reduce(0) { $0 + $1.count }
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 0

    var currentStreak = 0
    var longestStreak = 0

    // Calculate Longest Streak
    var tempLongestStreak = 0
    for day in (0..<valuationStore.currentDayNumber).reversed() {
      let dayDate = valuationStore.dateForDay(day)
      let dateKey = customDateFormatter(date: dayDate)

      if isDayActive(dateKey: dateKey) {
        tempLongestStreak += 1
      } else {
        longestStreak = max(longestStreak, tempLongestStreak)
        tempLongestStreak = 0  // Reset the streak
      }
    }
    longestStreak = max(longestStreak, tempLongestStreak)  // Check if the streak continues to the beginning of the year

    // Calculate Current Streak
    for day in (0..<valuationStore.currentDayNumber).reversed() {
      let dayDate = valuationStore.dateForDay(day)
      let dateKey = customDateFormatter(date: dayDate)

      // If the day is today, skip checking the entry to avoid resetting the streak
      if isToday(date: dayDate) {
        if isDayActive(dateKey: dateKey) {
          currentStreak += 1
        }
        continue
      }

      if isDayActive(dateKey: dateKey) {
        currentStreak += 1
      } else {
        break
      }
    }

    func isDayActive(dateKey: String) -> Bool {
      if let entry = calendar.entries[dateKey] {
        switch calendar.trackingType {
        case .binary:
          return entry.completed
        case .counter:
          return entry.count > 0
        case .multipleDaily:
          return entry.count >= calendar.dailyTarget
        }
      }
      return false
    }
    return CalendarStats(
      activeDays: activeDays, totalCount: totalCount, maxCount: maxCount,
      longestStreak: longestStreak, currentStreak: currentStreak)
  }

  // MARK: - Optimized stats computation (single pass + cache)

  private struct StatsBundle {
    let basic: CalendarStats
    let completionRate30d: Double
    let bestWeekday: Int?
    let weekdayRates: [Int: Double]
    let monthlyRates: [Int: Double]
    let rolling7d: Double
    let rolling30d: Double
    let volatilityStd: Double
  }

  private class StatsCache {
    private var cache: [String: StatsBundle] = [:]
    func get(_ key: String) -> StatsBundle? { cache[key] }
    func set(_ key: String, value: StatsBundle) { cache[key] = value }
  }
  private static let statsCache = StatsCache()

  private func makeCacheKey() -> String {
    // Key changes when year, today, or entries change (use entries count + max timestamp proxy)
    let year = valuationStore.selectedYear
    let entriesSignature = calendar.entries
      .sorted { $0.key < $1.key }
      .map { "\($0.key):\($0.value.count):\($0.value.completed ? 1 : 0)" }
      .joined(separator: ";")
    return "\(calendar.id.uuidString)|\(year)|\(entriesSignature)"
  }

  private func computeStatsBundle() -> StatsBundle {
    let key = makeCacheKey()
    if let cached = Self.statsCache.get(key) { return cached }

    // Precompute shared sequences
    let cal = Calendar.current
    let year = valuationStore.selectedYear
    let todayLocal = today

    // Basic stats and streaks (reuse existing logic for clarity)
    let basic = getStats()

    // Prepare fast lookup for entries
    func entryOn(_ date: Date) -> CalendarEntry? { store.getEntry(calendarId: calendar.id, date: date) }

    func success(_ e: CalendarEntry?) -> Bool { isEntrySuccess(e) }

    // Last 30 days CR + rolling averages on normalized progress
    let last30Dates = lastNDates(30)
    var successCount30 = 0
    var zSum7 = 0.0
    var zSum30 = 0.0
    for (idx, d) in last30Dates.enumerated() {
      let e = entryOn(d)
      if success(e) { successCount30 += 1 }
      let z = normalizedProgress(for: e)
      zSum30 += z
      if idx >= last30Dates.count - 7 { zSum7 += z }
    }
    let cr30 = last30Dates.isEmpty ? 0 : Double(successCount30) / Double(last30Dates.count)
    let avg7 = last30Dates.isEmpty ? 0 : zSum7 / Double(min(7, last30Dates.count))
    let avg30 = last30Dates.isEmpty ? 0 : zSum30 / Double(last30Dates.count)

    // Best weekday + weekday rates over selected year up to today
    var wdTotals: [Int: (succ: Int, denom: Int)] = [:]
    if let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
      let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))
    {
      var d = startOfYear
      let endDate = min(todayLocal, endOfYear)
      while d <= endDate {
        let wd = cal.component(.weekday, from: d)
        if let e = entryOn(d) {
          let s = success(e) ? 1 : 0
          let cur = wdTotals[wd] ?? (0, 0)
          wdTotals[wd] = (cur.succ + s, cur.denom + 1)
        }
        guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
        d = nd
      }
    }
    var weekdayRates: [Int: Double] = [:]
    var bestWD: (day: Int, rate: Double)? = nil
    for (day, pair) in wdTotals {
      let r = pair.denom > 0 ? Double(pair.succ) / Double(pair.denom) : 0
      weekdayRates[day] = r
      if bestWD == nil || r > bestWD!.rate { bestWD = (day, r) }
    }

    // Monthly breakdown over selected year
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
      var succ = 0
      for day in 1...lastDay {
        if let date = cal.date(from: DateComponents(year: year, month: m, day: day)) {
          succ += success(entryOn(date)) ? 1 : 0
        }
      }
      monthly[m] = Double(succ) / Double(max(1, lastDay))
    }

    // Weekly CR for volatility (look back 12 weeks)
    var weekly: [Double] = []
    var endOfWeek = todayLocal
    for _ in 0..<12 {
      guard let startOfWeek = cal.date(byAdding: .day, value: -6, to: endOfWeek) else { break }
      var succ = 0
      var denom = 0
      var d = startOfWeek
      while d <= endOfWeek {
        succ += success(entryOn(d)) ? 1 : 0
        denom += 1
        guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
        d = nd
      }
      weekly.append(denom > 0 ? Double(succ) / Double(denom) : 0)
      guard let prev = cal.date(byAdding: .day, value: -7, to: endOfWeek) else { break }
      endOfWeek = prev
    }
    let volatility = {
      guard !weekly.isEmpty else { return 0.0 }
      let mean = weekly.reduce(0, +) / Double(weekly.count)
      let variance = weekly.reduce(0) { $0 + pow($1 - mean, 2) } / Double(weekly.count)
      return sqrt(variance)
    }()

    let computed = StatsBundle(
      basic: basic,
      completionRate30d: cr30,
      bestWeekday: bestWD?.day,
      weekdayRates: weekdayRates,
      monthlyRates: monthly,
      rolling7d: avg7,
      rolling30d: avg30,
      volatilityStd: volatility
    )
    Self.statsCache.set(key, value: computed)
    return computed
  }
  private func isPremium() -> Bool {
    customerInfo?.entitlements["premium"]?.isActive ?? false
  }

  private func isEntrySuccess(_ entry: CalendarEntry?) -> Bool {
    guard let entry = entry else { return false }
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter:
      return entry.count > 0
    case .multipleDaily:
      return entry.count >= calendar.dailyTarget
    }
  }

  private func entryFor(date: Date) -> CalendarEntry? {
    store.getEntry(calendarId: calendar.id, date: date)
  }

  private func lastNDates(_ n: Int) -> [Date] {
    let cal = Calendar.current
    let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(n - 1), to: today)!)
    return (0..<n).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
      .filter { $0 <= today }
  }

  private func completionRateLastNDays(_ n: Int) -> Double {
    let dates = lastNDates(n)
    if dates.isEmpty { return 0 }
    let successes = dates.reduce(0) { partial, d in
      partial + (isEntrySuccess(entryFor(date: d)) ? 1 : 0)
    }
    return Double(successes) / Double(dates.count)
  }

  private func bestWeekdayCR() -> (weekday: Int?, rates: [Int: Double]) {
    let cal = Calendar.current
    // Look back over the selected year up to today
    let currentYear = valuationStore.selectedYear
    guard let startOfYear = cal.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
      return (nil, [:])
    }
    let endDate = min(today, cal.date(from: DateComponents(year: currentYear, month: 12, day: 31))!)
    var totals: [Int: (succ: Int, denom: Int)] = [:]
    var d = startOfYear
    while d <= endDate {
      let weekday = cal.component(.weekday, from: d)
      let success = isEntrySuccess(entryFor(date: d)) ? 1 : 0
      let current = totals[weekday] ?? (0, 0)
      totals[weekday] = (current.succ + success, current.denom + 1)
      guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
      d = next
    }
    var rates: [Int: Double] = [:]
    var bestDay: (day: Int, rate: Double)? = nil
    for (day, pair) in totals {
      let rate = pair.denom > 0 ? Double(pair.succ) / Double(pair.denom) : 0
      rates[day] = rate
      if let currentBest = bestDay {
        if rate > currentBest.rate { bestDay = (day, rate) }
      } else {
        bestDay = (day, rate)
      }
    }
    return (bestDay?.day, rates)
  }

  private func monthlyCompletionRatesForSelectedYear() -> [Int: Double] {
    let cal = Calendar.current
    let year = valuationStore.selectedYear
    var result: [Int: Double] = [:]
    for month in 1...12 {
      guard let start = cal.date(from: DateComponents(year: year, month: month, day: 1)) else { continue }
      guard let range = cal.range(of: .day, in: .month, for: start) else { continue }
      let isCurrentMonth = (year == cal.component(.year, from: today) && month == cal.component(.month, from: today))
      let lastDay = isCurrentMonth ? cal.component(.day, from: today) : range.count
      if lastDay <= 0 {
        result[month] = 0
        continue
      }
      var succ = 0
      var denom = 0
      for day in 1...lastDay {
        if let date = cal.date(from: DateComponents(year: year, month: month, day: day)) {
          succ += isEntrySuccess(entryFor(date: date)) ? 1 : 0
          denom += 1
        }
      }
      result[month] = denom > 0 ? Double(succ) / Double(denom) : 0
    }
    return result
  }

  private func percentile(_ values: [Int], p: Double) -> Double {
    let sorted = values.sorted()
    if sorted.isEmpty { return 1 }
    let pos = max(0, min(Double(sorted.count - 1), p * Double(sorted.count - 1)))
    let lower = Int(floor(pos))
    let upper = Int(ceil(pos))
    if lower == upper { return Double(sorted[lower]) }
    let weight = pos - Double(lower)
    return Double(sorted[lower]) * (1 - weight) + Double(sorted[upper]) * weight
  }

  private func normalizedProgress(for entry: CalendarEntry?) -> Double {
    guard let entry = entry else { return 0 }
    switch calendar.trackingType {
    case .binary:
      return entry.completed ? 1 : 0
    case .counter:
      // Use 75th percentile as reference q
      let counts =
        store.calendars
        .first(where: { $0.id == calendar.id })?
        .entries.values.map { $0.count } ?? []
      let q = max(1.0, percentile(counts, p: 0.75))
      return min(Double(entry.count) / q, 1.0)
    case .multipleDaily:
      let target = max(1, calendar.dailyTarget)
      return min(Double(entry.count) / Double(target), 1.0)
    }
  }

  private func rollingAverage(_ k: Int) -> Double {
    let dates = lastNDates(k)
    if dates.isEmpty { return 0 }
    let sum = dates.reduce(0.0) { partial, d in
      partial + normalizedProgress(for: entryFor(date: d))
    }
    return sum / Double(dates.count)
  }

  private func weeklyCompletionRates(lookbackWeeks: Int = 12) -> [Double] {
    let cal = Calendar.current
    var rates: [Double] = []
    var endOfWeek = today
    for _ in 0..<lookbackWeeks {
      guard let startOfWeek = cal.date(byAdding: .day, value: -6, to: endOfWeek) else { break }
      var succ = 0
      var denom = 0
      var d = startOfWeek
      while d <= endOfWeek {
        succ += isEntrySuccess(entryFor(date: d)) ? 1 : 0
        denom += 1
        guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
        d = nd
      }
      rates.append(denom > 0 ? Double(succ) / Double(denom) : 0)
      guard let prevEnd = cal.date(byAdding: .day, value: -7, to: endOfWeek) else { break }
      endOfWeek = prevEnd
    }
    return rates.reversed()
  }

  private func stdDev(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
  }

  private func handleQuickAdd() {
    quickEntry(
      calendar: calendar,
      date: today,
      calendarStore: store,
      valuationStore: valuationStore
    )

    WidgetCenter.shared.reloadAllTimelines()

    Task {
      await hapticFeedback()
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        // Stats header
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(calendar.name.capitalized)
                  .font(.system(size: 36, design: .monospaced))
                  .lineLimit(2)
                  .minimumScaleFactor(0.5)
                  .foregroundColor(Color("text-primary"))
                  .fontWeight(.black)
                  .onTapGesture {
                    router.showScreen(.sheet) { _ in
                      EditCalendarView(
                        calendar: calendar,
                        onSave: { updatedCalendar in
                          store.updateCalendar(updatedCalendar)
                        },
                        onDelete: { _ in
                          store.deleteCalendar(id: calendar.id)
                        }
                      )

                    }
                  }
                  .padding(.top)
                Spacer()

                let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)

                if My_YearApp.isDebugMode && runtimeDebugEnabled {
                  Button(action: fillRandomEntries) {
                    Image(systemName: "wand.and.stars")
                      .foregroundColor(Color(calendar.color))
                  }
                  .padding(.horizontal, 4)
                }

                Button(action: {
                  handleQuickAdd()
                }) {
                  ZStack {
                    RoundedRectangle(cornerRadius: 3)
                      .fill(Color(calendar.color).opacity(0.1))
                      .frame(width: 20, height: 20)

                    Image(
                      systemName: calendar.trackingType == .binary
                        && store.getEntry(calendarId: calendar.id, date: today) != nil
                        && store.getEntry(calendarId: calendar.id, date: today)!.completed
                        ? "minus" : "plus"
                    )
                    .font(.system(size: 16))
                    .foregroundColor(Color(calendar.color))
                  }
                }.frame(width: 24, height: 24)

              }

              HStack(spacing: 4) {
                Button(action: { showingYearPicker = true }) {
                  Text("\(valuationStore.year.description)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                }

                if calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
                  let minute = calendar.reminderMinute
                {
                  Text("•")
                    .font(.system(size: 4, weight: .black, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                    .padding(.horizontal, 2)

                  HStack(alignment: .center, spacing: 4) {
                    let reminderTime = String(format: "%02d:%02d", hour, minute)
                    Image(systemName: "bell")
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                    Text(reminderTime)
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                  }.onTapGesture {
                    router.showScreen(
                      .sheet
                    ) { _ in
                      EditCalendarView(
                        calendar: calendar,
                        onSave: { updatedCalendar in
                          store.updateCalendar(updatedCalendar)
                        },
                        onDelete: { _ in
                          store.deleteCalendar(id: calendar.id)
                        }
                      )

                    }
                  }
                }
              }
            }
          }
          .padding(.horizontal)
          .padding(.top, 10)
          CustomSeparator()
        }

        GridView(
          calendar: calendar,
          store: store,
          valuationStore: valuationStore,
          handleDayTap: handleDayTap
        )

      }
      .frame(height: UIScreen.main.bounds.height * 0.85)

      // Calculate today's count
      let todayDateString = customDateFormatter(date: today)
      let todaysLogCount = calendar.entries[todayDateString]?.count ?? 0

      let bundle = computeStatsBundle()

      CalendarStatisticsView(
        stats: bundle.basic,
        accentColor: Color(calendar.color),
        todaysCount: todaysLogCount,
        unit: calendar.unit,
        currencySymbol: calendar.currencySymbol,
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
        Text("Independently engineered. Lovingly crafted.")
        Text("Thank you for your support!")

        Spacer()
        HStack(spacing: 4) {
          Text("Mykhaylo Tymofyeyev")
          Text("•")
          Text("[@tymofyeyev_m](https://x.com/tymofyeyev_m)").foregroundColor(Color(calendar.color))
        }
        .foregroundColor(Color("text-tertiary"))

      }.padding(.horizontal)
        .font(.system(size: 9, design: .monospaced))
        .foregroundColor(Color("text-tertiary").opacity(0.5))
        .multilineTextAlignment(.center)
        .padding(.bottom, 40)

    }.scrollIndicators(.hidden)
      .refreshable {
        store.loadCalendars()
        WidgetCenter.shared.reloadAllTimelines()
      }
      .sheet(isPresented: $showingYearPicker) {
        NavigationStack {
          VStack {
            Picker("Select Year", selection: $tempSelectedYear) {
              ForEach(availableYears, id: \.self) { year in
                Text(year.description)
                  .foregroundColor(Color("text-primary"))
                  .tag(year)
              }
            }
            .pickerStyle(.wheel)
          }
          .navigationTitle("Select Year")
          .navigationBarTitleDisplayMode(.large)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                tempSelectedYear = valuationStore.selectedYear
                showingYearPicker = false
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                valuationStore.selectedYear = tempSelectedYear
                showingYearPicker = false
              }
            }
          }
          .onAppear {
            tempSelectedYear = valuationStore.selectedYear
          }
          .background(Color("surface-muted"))
        }
        .background(Color("surface-muted"))
        .presentationDetents([.height(280)])
      }
      .sheet(isPresented: $isPaywallPresented) {
        PaywallView()
      }
      .overlay {
        HStack {
          Rectangle()
            .fill(Color("devider-bottom"))
            .frame(maxHeight: .infinity, alignment: .trailing)
            .frame(maxWidth: 1)

          Spacer()

          Rectangle()
            .fill(Color("devider-top"))
            .frame(maxHeight: .infinity, alignment: .trailing)
            .frame(maxWidth: 1)

        }
      }
      .ignoresSafeArea(edges: .bottom)
      .alert(item: $calendarError) { error in
        Alert(
          title: Text(error.title), message: Text(error.message),
          dismissButton: .default(Text("OK")))
      }
      .onAppear {
        Purchases.shared.getCustomerInfo { info, _ in
          self.customerInfo = info
        }
      }
  }
}

enum CalendarError: LocalizedError, Identifiable {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)

  var id: String { self.localizedDescription }

  var title: String {
    switch self {
    case .invalidName:
      return "Invalid Name"
    case .notificationPermissionDenied:
      return "Notification Permission Denied"
    case .notificationSchedulingFailed:
      return "Notification Error"
    case .errorAddingEntry:
      return "Entry Error"
    }
  }

  var message: String {
    errorDescription ?? "An unknown error occurred."
  }

  var errorDescription: String? {
    switch self {
    case .invalidName:
      return "Please enter a valid name (1-50 characters)"
    case .notificationPermissionDenied:
      return "Please enable notifications in Settings to receive reminders."
    case .notificationSchedulingFailed(let error):
      return "Failed to schedule notification: \(error.localizedDescription)"
    case .errorAddingEntry(let error):
      return "Failed to add entry: \(error.localizedDescription)"
    }
  }
}
