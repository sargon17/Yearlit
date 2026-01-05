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
  @State private var statsBundle: StatsBundle? = nil
  @State private var cachedStatsBundle: StatsBundle? = nil
  @State private var didUseDiskStatsCache: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var statsRefreshToken = UUID()
  @State private var lastObservedDataVersion: Int = 0

  private static let daySeedFormatter = ISO8601DateFormatter()
  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func makeCacheKey(year: Int, daySeed: Date, dataVersion: Int) -> CacheKey {
    let daySeedStr = Self.daySeedFormatter.string(from: daySeed)
    let identifier = "overall|\(year)|\(daySeedStr)|v\(dataVersion)"
    return CacheKey(scope: .overviewStatsBundle, identifier: identifier)
  }

  private func computeOverallStats(
    calendars: [CustomCalendar],
    year: Int,
    todayLocal: Date,
    todayKeyDate: Date?
  ) -> StatsBundle {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "en_US_POSIX")
    cal.timeZone = .autoupdatingCurrent
    let entriesByCalendar = Dictionary(uniqueKeysWithValues: calendars.map { ($0.id, $0.entries) })
    let (totalCount, perDayTotal) = aggregateCounts(cal: cal, calendars: calendars)
    let maxCount = perDayTotal.values.max() ?? 0

    let (anySuccessByDay, dayMeanZ) = buildDailyMaps(
      cal: cal,
      year: year,
      todayLocal: todayLocal,
      calendars: calendars,
      entriesByCalendar: entriesByCalendar
    )

    let allTimeSuccessByDay = buildAllTimeSuccessMap(
      cal: cal,
      todayLocal: todayLocal,
      calendars: calendars
    )
    let activeDays = allTimeSuccessByDay.values.filter { $0 }.count
    let (longestStreak, currentStreak) = computeStreaks(cal: cal, allTimeSuccessByDay)

    let todayKeyCount: Int? = {
      guard let keyDate = todayKeyDate else { return nil }
      let key = dayKey(for: cal.startOfDay(for: keyDate))
      return calendars.reduce(0) { partial, c in
        let e = entry(for: c.id, dayKey: key, entriesByCalendar: entriesByCalendar)
        return partial + (e?.count ?? 0)
      }
    }()

    let (cr30, avg7, avg30) = computeRollingStats(
      cal: cal,
      todayLocal: todayLocal,
      calendars: calendars,
      anySuccessByDay: anySuccessByDay,
      entriesByCalendar: entriesByCalendar
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

    return bundle
  }

  var body: some View {
    let selectedYear = valuationStore.selectedYear
    let calendars = store.calendars
    let dataVersion = store.dataVersion
    let daySeed = Calendar.current.startOfDay(for: Date())
    let daySeedKey = Self.daySeedFormatter.string(from: daySeed)
    let statsSignature = makeCacheKey(year: selectedYear, daySeed: daySeed, dataVersion: dataVersion)
    let statsTaskId = "\(statsSignature.identifier)|\(statsRefreshToken.uuidString)"
    let todayKeyDate = getYearDatesArray(for: selectedYear).first { Calendar.current.isDate($0, inSameDayAs: Date()) }

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
                Button(action: { showingYearPicker = true }) {
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

        OverallGridView(
          accentColor: Color("qs-emerald"),
          store: store,
          dates: getYearDatesArray(for: selectedYear),
          year: selectedYear
        )
        .frame(height: UIScreen.main.bounds.height * 0.55)

        if let bundle = statsBundle ?? cachedStatsBundle {
          CalendarStatisticsView(
            stats: bundle.basic,
            accentColor: Color("qs-emerald"),
            todaysCount: bundle.todaysCount ?? 0,
            unit: nil,
            currencySymbol: nil,
            completionRateLast30d: bundle.completionRate30d,
            bestWeekday: bundle.bestWeekday,
            weekdayRates: bundle.weekdayRates,
            monthlyRates: bundle.monthlyRates,
            rolling7d: bundle.rolling7d,
            rolling30d: bundle.rolling30d,
            volatilityStdDev: bundle.volatilityStd,
            isPremium: isPremium(customerInfo: customerInfo),
            onUpgrade: { isPaywallPresented = true }
          )
          .id(colorScheme)
          .padding(.top, 20)
        }

      }
      .frame(maxWidth: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .scrollIndicators(.hidden)
    .sheet(isPresented: $isPaywallPresented) {
      PaywallView()
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
      }
      .presentationDetents([.height(280)])
    }
    .onAppear {
      Purchases.shared.getCustomerInfo { info, _ in
        self.customerInfo = info
      }
      if lastObservedDataVersion != store.dataVersion {
        lastObservedDataVersion = store.dataVersion
        statsRefreshToken = UUID()
      }
    }
    .onChange(of: statsSignature) { _, _ in
      didUseDiskStatsCache = false
    }
    .onChange(of: store.dataVersion) { _, _ in
      lastObservedDataVersion = store.dataVersion
      didUseDiskStatsCache = false
      cachedStatsBundle = nil
      statsRefreshToken = UUID()
    }
    .onChange(of: store.isLoading) { _, isLoading in
      if !isLoading {
        didUseDiskStatsCache = false
        cachedStatsBundle = nil
        statsRefreshToken = UUID()
      }
    }
    .onReceive(store.$calendars) { _ in
      CacheStore.shared.removeDisk(statsSignature)
      didUseDiskStatsCache = false
      cachedStatsBundle = nil
      statsRefreshToken = UUID()
    }
    .task(id: statsTaskId) {
      let token = statsRefreshToken
      if didUseDiskStatsCache { return }
      if loadStatsBundleFromDisk(cacheKey: statsSignature) != nil {
        didUseDiskStatsCache = true
        return
      }
      if store.isLoading { return }
      let calendarsSnapshot = await MainActor.run { store.calendars }
      let currentVersion = await MainActor.run { store.dataVersion }
      guard currentVersion == dataVersion else { return }
      let bundle = await Task.detached(priority: .userInitiated) {
        computeOverallStats(
          calendars: calendarsSnapshot,
          year: selectedYear,
          todayLocal: Date(),
          todayKeyDate: todayKeyDate
        )
      }.value
      if token == statsRefreshToken {
        statsBundle = bundle
        saveStatsBundleToDisk(bundle, cacheKey: statsSignature)
      }
    }
    .task(id: statsSignature) {
      if cachedStatsBundle == nil {
        if let cached = loadStatsBundleFromDisk(cacheKey: statsSignature) {
          cachedStatsBundle = cached
          didUseDiskStatsCache = true
        }
      }
    }
  }
}

private extension AllCalendarsRecapView {
  func loadStatsBundleFromDisk(cacheKey: CacheKey) -> StatsBundle? {
    guard let snapshot: StatsBundleSnapshot = CacheStore.shared.loadDisk(cacheKey) else { return nil }
    return snapshot.toBundle()
  }

  func saveStatsBundleToDisk(_ bundle: StatsBundle, cacheKey: CacheKey) {
    let snapshot = StatsBundleSnapshot(bundle: bundle)
    CacheStore.shared.saveDisk(cacheKey, value: snapshot)
  }
}

#Preview {
  AllCalendarsRecapView()
}
