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

  @Environment(\.colorScheme) var colorScheme
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

    let cal = Calendar.current
    let year = valuationStore.selectedYear
    let todayLocal = today

    // Riusa: getStats() già esistente per basic
    let basic = getStats()

    // Adattatori leggeri
    func entryOn(_ date: Date) -> CalendarEntry? {
      store.getEntry(calendarId: calendar.id, date: date)
    }
    func isSuccessOn(_ date: Date) -> Bool {
      isEntrySuccess(entryOn(date), calendar: calendar)
    }
    func zOn(_ date: Date) -> Double {
      normalizedProgress(for: calendar, entry: entryOn(date))
    }

    let (cr30, avg7, avg30) = computeRollingStatsSingle(
      cal: cal, todayLocal: todayLocal, zOn: zOn, isSuccessOn: isSuccessOn
    )

    // Nuovo: weekday rates per singolo calendario + best day (normalizzati a max=1)
    let (weekdayRates, bestWD) = computeWeekdayRatesSingle(
      cal: cal, year: year, todayLocal: todayLocal,
      trackingType: calendar.trackingType, zOn: zOn, isSuccessOn: isSuccessOn,
      normalizeToMax: true
    )

    // Nuovo: breakdown mensile (CR binaria sul mese)
    let monthly = computeMonthlyBinaryRates(
      cal: cal, year: year, todayLocal: todayLocal, isSuccessOn: isSuccessOn
    )

    // Riusa schema: volatilità settimanale su CR (12 settimane)
    let volatility = computeWeeklyVolatilityFromSuccess(
      cal: cal, todayLocal: todayLocal, isSuccessOn: isSuccessOn
    )

    let bundle = StatsBundle(
      basic: basic,
      completionRate30d: cr30,
      bestWeekday: bestWD?.day,
      weekdayRates: weekdayRates,
      monthlyRates: monthly,
      rolling7d: avg7,
      rolling30d: avg30,
      volatilityStd: volatility
    )
    Self.statsCache.set(key, value: bundle)
    return bundle
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
        isPremium: isPremium(customerInfo: customerInfo),
        onUpgrade: { isPaywallPresented = true },
        trackingType: calendar.trackingType
      )
      .id(colorScheme)
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
