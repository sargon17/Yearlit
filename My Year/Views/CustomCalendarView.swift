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
  @StateObject private var store: CustomCalendarStore = .shared
  @ObservedObject private var timelinePreference = TimelinePreferenceManager.shared
  @ObservedObject private var valuationStore: ValuationStore = .shared

  @AppStorage(AppStorageKeys.runtimeDebugEnabled) private var runtimeDebugEnabled: Bool = false
  @AppStorage(AppStorageKeys.wandFillForce) private var wandFillForce: Double = 0.5
  @AppStorage(AppStorageKeys.isDeveloperModeEnabled) private var isDeveloperModeEnabled: Bool = false
  @State private var today: Date = Calendar.current.startOfDay(for: Date())
  @Environment(\.scenePhase) private var scenePhase

  private struct OptimisticEntryOverride {
    let calendarId: UUID
    let dayKey: String
    let entry: CalendarEntry?
  }

  private var renderSnapshot: CalendarRenderSnapshot {
    makeRenderSnapshot(snapshot: store.snapshot, selectedYear: valuationStore.selectedYear)
  }

  private func makeRenderSnapshot(
    snapshot: CustomCalendarStoreSnapshot,
    selectedYear: Int
  ) -> CalendarRenderSnapshot {
    let activeCalendar = applyingOptimisticEntryOverrides(to: snapshot.calendar(id: calendar.id) ?? calendar)
    return CalendarRenderSnapshotCache.snapshot(
      calendar: activeCalendar,
      selectedYear: selectedYear,
      timelineMode: timelinePreference.mode,
      today: today,
      colorScheme: colorScheme,
      optimisticOverridesSignature: optimisticOverridesSignature
    )
  }

  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?
  @State private var customerInfo: CustomerInfo?
  @State private var isPaywallPresented: Bool = false
  @State private var statsBundle: StatsBundle?
  @State private var pendingMilestoneCheck: Bool = false
  @State private var isEntryEditSheetPresented: Bool = false
  @State private var optimisticEntryOverrides: [String: OptimisticEntryOverride] = [:]

  private let milestoneCelebrationPolicy = MilestoneCelebrationPolicy.shared

  @Environment(\.router) private var router

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func fillRandomEntries() {
    let state = renderSnapshot
    let activeCalendar = state.activeCalendar

    // TODO: Implement clearEntries(calendarId:) in CustomCalendarStore to enable clearing before filling.
    store.clearEntries(calendarId: activeCalendar.id)

    let sourceDates =
      state.isShowingYour365
      ? state.your365Snapshot?.cells.map(\.date) ?? []
      : state.calendarYearGridDates

    for date in sourceDates {
      if date <= today, Double.random(in: 0.0...1.0) < wandFillForce {
        switch activeCalendar.trackingType {
        case .binary:
          let entry = CalendarEntry(date: date, count: 1, completed: true)
          store.addEntry(calendarId: activeCalendar.id, entry: entry)
        case .counter:
          let count = Int.random(in: 1...5)
          let entry = CalendarEntry(date: date, count: count, completed: count > 0)
          store.addEntry(calendarId: activeCalendar.id, entry: entry)
        case .multipleDaily:
          let count = Int.random(in: 1...activeCalendar.dailyTarget)
          let entry = CalendarEntry(
            date: date, count: count, completed: count >= activeCalendar.dailyTarget
          )
          store.addEntry(calendarId: activeCalendar.id, entry: entry)
        }
      }
    }
  }

  private func applyingOptimisticEntryOverrides(to calendar: CustomCalendar) -> CustomCalendar {
    var calendar = calendar
    for override in optimisticEntryOverrides.values where override.calendarId == calendar.id {
      if let entry = override.entry {
        calendar.entries[override.dayKey] = entry
      } else {
        calendar.entries.removeValue(forKey: override.dayKey)
      }
    }
    return calendar
  }

  private func setOptimisticEntryOverride(calendar: CustomCalendar, date: Date, entry: CalendarEntry?) {
    let dayKey = calendar.entryKey(for: date)
    optimisticEntryOverrides["\(calendar.id.uuidString)|\(dayKey)"] = OptimisticEntryOverride(
      calendarId: calendar.id,
      dayKey: dayKey,
      entry: entry
    )
  }

  private func handleDayTap(_ date: Date) {
    guard !date.isInFuture else { return }

    let activeCalendar = renderSnapshot.activeCalendar

    if activeCalendar.trackingType == .binary {
      let newEntry =
        activeCalendar.entry(for: date) == nil
        ? defaultEntry(date: date, trackingType: .binary)
        : nil
      setOptimisticEntryOverride(calendar: activeCalendar, date: date, entry: newEntry)

      Task { @MainActor in
        await hapticFeedback()
        _ = toggleBinaryEntry(
          calendarId: activeCalendar.id,
          date: date,
          calendarStore: store,
          source: .calendar
        )
        scheduleMilestoneCheck()
        checkIfReachedThreeDays(activeCalendar)
      }
      return
    }

    Task {
      await hapticFeedback()
    }
    isEntryEditSheetPresented = true
    router.showScreen(
      .sheetConfig(config: shortSheetConfig)
    ) { _ in
      DayEntryEditSheet(
        calendar: activeCalendar,
        date: date,
        store: store,
        onSave: {
          scheduleMilestoneCheck()
        },
        onDismiss: {
          isEntryEditSheetPresented = false
          evaluateMilestonesIfNeeded(calendarId: activeCalendar.id)
        }
      )
    }
  }

  private func handleQuickAdd() {
    let state = renderSnapshot
    let activeCalendar = state.activeCalendar
    let entryDate = state.currentPeriodReferenceDate ?? Date()

    Task { @MainActor in
      await hapticFeedback()
      quickEntry(
        calendar: activeCalendar,
        date: entryDate,
        calendarStore: store,
        source: .calendar
      )

      checkIfReachedThreeDays(activeCalendar)
      scheduleMilestoneCheck()
    }
  }

  private func scheduleMilestoneCheck() {
    pendingMilestoneCheck = true
  }

  private func evaluateMilestonesIfNeeded(calendarId: UUID) {
    guard pendingMilestoneCheck else { return }
    pendingMilestoneCheck = false
    let referenceDate = Date()
    guard let updatedCalendar = store.snapshot.calendar(id: calendarId) else { return }
    let currentStreak = currentStreak(for: updatedCalendar)

    if celebrateStreakMilestoneIfNeeded(
      calendar: updatedCalendar,
      calendarId: calendarId,
      currentStreak: currentStreak
    ) {
      return
    }

    if updatedCalendar.cadence == .daily {
      for kind in [ShowedUpMilestoneKind.currentMonth, .currentYear] {
        if celebrateShowedUpMilestoneIfNeeded(
          calendar: updatedCalendar,
          calendarId: calendarId,
          currentStreak: currentStreak,
          kind: kind,
          referenceDate: referenceDate
        ) {
          return
        }
      }
    }

    _ = celebrateShowedUpMilestoneIfNeeded(
      calendar: updatedCalendar,
      calendarId: calendarId,
      currentStreak: currentStreak,
      kind: .allTime,
      referenceDate: referenceDate
    )
  }

  @discardableResult
  private func celebrateStreakMilestoneIfNeeded(
    calendar: CustomCalendar,
    calendarId: UUID,
    currentStreak: Int
  ) -> Bool {
    guard
      let decision = milestoneCelebrationPolicy.decisionForStreakMilestone(
        calendarId: calendarId,
        streak: currentStreak
      )
    else { return false }

    guard decision.shouldPresent else { return false }

    router.showScreen(.sheet) { _ in
      MilestoneCelebrationSheet(
        calendar: calendar,
        milestone: decision.milestone,
        currentStreak: currentStreak,
        kind: .streak,
        dates: renderSnapshot.visibleGridDates,
        allowsStopShowing: true,
        showedUpPeriodKey: nil
      )
    }
    return true
  }

  @discardableResult
  private func celebrateShowedUpMilestoneIfNeeded(
    calendar: CustomCalendar,
    calendarId: UUID,
    currentStreak: Int,
    kind: ShowedUpMilestoneKind,
    referenceDate: Date
  ) -> Bool {
    let periodKey = ShowedUpMilestones.periodKey(for: kind, today: referenceDate)
    let showedUpCount = ShowedUpMilestones.showedUpCount(for: calendar, kind: kind, today: referenceDate)

    guard
      let decision = milestoneCelebrationPolicy.decisionForShowedUpMilestone(
        calendarId: calendarId,
        showedUpCount: showedUpCount,
        kind: kind,
        periodKey: periodKey
      )
    else { return false }

    guard decision.shouldPresent else { return false }

    router.showScreen(.sheet) { _ in
      MilestoneCelebrationSheet(
        calendar: calendar,
        milestone: decision.milestone,
        currentStreak: currentStreak,
        kind: milestoneKind(for: kind),
        dates: milestoneDates(for: kind, referenceDate: referenceDate),
        allowsStopShowing: true,
        showedUpPeriodKey: periodKey
      )
    }
    return true
  }

  private func milestoneKind(for kind: ShowedUpMilestoneKind) -> MilestoneKind {
    switch kind {
    case .allTime:
      .showedUp
    case .currentMonth:
      .showedUpMonth
    case .currentYear:
      .showedUpYear
    }
  }

  private func milestoneDates(for kind: ShowedUpMilestoneKind, referenceDate: Date) -> [Date] {
    switch kind {
    case .allTime:
      return renderSnapshot.calendarYearGridDates
    case .currentMonth:
      let referenceYear = LocalDayCalendar.calendar.component(.year, from: referenceDate)
      return getYearDatesArray(for: referenceYear).filter {
        LocalDayCalendar.calendar.isDate($0, equalTo: referenceDate, toGranularity: .month)
      }
    case .currentYear:
      let referenceYear = LocalDayCalendar.calendar.component(.year, from: referenceDate)
      return getYearDatesArray(for: referenceYear)
    }
  }

  private func currentStreak(for calendar: CustomCalendar) -> Int {
    WidgetStreak.currentStreak(calendar: calendar).streak
  }

  private func showedUpCount(for calendar: CustomCalendar) -> Int {
    ShowedUpMilestones.showedUpCount(for: calendar, kind: .allTime)
  }

  var body: some View {
    let snapshot = store.snapshot
    let selectedYear = valuationStore.selectedYear
    let renderSnapshot = makeRenderSnapshot(snapshot: snapshot, selectedYear: selectedYear)
    let activeCalendar = renderSnapshot.activeCalendar
    let isStoreLoading = snapshot.isLoading
    let statsTaskId = [
      renderSnapshot.cacheKey,
      isStoreLoading ? "loading" : "hydrated"
    ].joined(separator: "|")
    ScrollView {
      VStack(spacing: 10) {
        // Stats header
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(activeCalendar.name.capitalized)
                  .font(AppFont.sans(36))
                  .fontWeight(.black)
                  .lineLimit(2)
                  .minimumScaleFactor(0.5)
                  .foregroundColor(Color("text-primary"))
                  .onTapGesture {
                    router.showScreen(.sheet) { _ in
                      EditCalendarView(
                        calendar: activeCalendar,
                        onSave: { updatedCalendar in
                          store.updateCalendar(updatedCalendar)
                        },
                        onDelete: { _ in
                          store.deleteCalendar(id: activeCalendar.id)
                        }
                      )
                    }
                  }
                  .padding(.top)
                Spacer()

                let currentDayDate = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)

                if (My_YearApp.isDebugMode && runtimeDebugEnabled) || isDeveloperModeEnabled {
                  Button(action: fillRandomEntries) {
                    Image(systemName: "wand.and.stars")
                      .foregroundColor(Color(activeCalendar.color))
                  }
                  .padding(.horizontal, 4)
                }

                let currentYear = Calendar.current.component(.year, from: Date())
                if renderSnapshot.isShowingYour365 || valuationStore.selectedYear == currentYear {
                  let quickAddDate = renderSnapshot.currentPeriodReferenceDate ?? currentDayDate
                  let isCompletedToday =
                    store.getEntry(
                      calendarId: activeCalendar.id,
                      date: quickAddDate
                    )?.completed == true
                  Button(action: {
                    handleQuickAdd()
                  }) {
                    ZStack {
                      RoundedRectangle(cornerRadius: 3)
                        .fill(Color(activeCalendar.color).opacity(0.1))
                        .frame(width: 20, height: 20)

                      Image(
                        systemName: activeCalendar.trackingType == .binary
                          && isCompletedToday
                          ? "minus" : "plus"
                      )
                      .font(.system(size: 16))
                      .foregroundColor(Color(activeCalendar.color))
                    }
                  }.frame(width: 24, height: 24)
                }
              }

              HStack(spacing: 10) {
                if renderSnapshot.isShowingYour365 {
                  VStack(alignment: .leading, spacing: 2) {
                    if let title = renderSnapshot.your365HeaderTitle {
                      Text(title)
                        .font(AppFont.mono(12))
                        .foregroundColor(Color("text-tertiary"))
                    }
                  }
                } else {
                  Button(action: { showingYearPicker = true }) {
                    Text("\(valuationStore.year.description)")
                      .font(AppFont.mono(12))
                      .foregroundColor(Color("text-tertiary"))
                  }

                  Text("•")
                    .font(AppFont.mono(4, weight: .black))
                    .foregroundColor(Color("text-tertiary"))
                    .padding(.horizontal, 2)
                }

                HStack(alignment: .center, spacing: 4) {
                  if activeCalendar.recurringReminderEnabled,
                    let hour = activeCalendar.reminderHour,
                    let minute = activeCalendar.reminderMinute
                  {
                    let reminderTime = String(format: "%02d:%02d", hour, minute)
                    Image(systemName: "bell")
                      .font(AppFont.mono(12))
                      .foregroundColor(Color("text-tertiary"))
                    Text(reminderTime)
                      .font(AppFont.mono(12))
                      .foregroundColor(Color("text-tertiary"))
                  } else {
                    Image(systemName: "bell.slash")
                      .font(AppFont.mono(12))
                      .foregroundColor(Color("text-tertiary"))
                    Text("Off")
                      .font(AppFont.mono(12))
                      .foregroundColor(Color("text-tertiary"))
                  }
                }
                .onTapGesture {
                  router.showScreen(.sheet) { _ in
                    NotificationSettingsSheet(
                      calendar: activeCalendar,
                      customerInfo: customerInfo,
                      onSave: { updatedCalendar in
                        store.updateCalendar(updatedCalendar)
                      }
                    )
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
          handleDayTap: handleDayTap,
          mappedDays: renderSnapshot.mappedGridDays,
          disabledDates: renderSnapshot.disabledGridDates
        )
        .id(renderSnapshot.timelineMode.rawValue)
        .frame(height: UIScreen.main.bounds.height * 0.55)

        let currentPeriodLogCount: Int? = renderSnapshot.currentPeriodReferenceDate.map {
          entry(for: activeCalendar, date: $0)?.count ?? 0
        }

        if let bundle = statsBundle {
          CalendarStatisticsView(
            stats: bundle.basic,
            accentColor: Color(activeCalendar.color),
            currentPeriodCount: currentPeriodLogCount,
            unit: activeCalendar.unit,
            currencySymbol: activeCalendar.currencySymbol,
            completionRateTrailingLongWindow: bundle.completionRateTrailingLongWindow,
            bestWeekday: bundle.bestWeekday,
            weekdayRates: bundle.weekdayRates,
            monthlyRates: bundle.monthlyRates,
            averageProgressTrailingShortWindow: bundle.averageProgressTrailingShortWindow,
            averageProgressTrailingLongWindow: bundle.averageProgressTrailingLongWindow,
            volatilityStdDev: bundle.volatilityStd,
            isPremium: isPremium(customerInfo: customerInfo),
            onUpgrade: { isPaywallPresented = true },
            cadence: activeCalendar.cadence,
            trackingType: activeCalendar.trackingType,
            onTapCurrentStreak: {
              guard
                let milestone = StreakMilestones.latestMilestone(
                  for: currentStreak(for: activeCalendar)
                )
              else { return }
              router.showScreen(.sheet) { _ in
                MilestoneCelebrationSheet(
                  calendar: activeCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: activeCalendar),
                  kind: .streak,
                  dates: renderSnapshot.visibleGridDates,
                  allowsStopShowing: false,
                  showedUpPeriodKey: nil
                )
              }
            },
            onTapActiveDays: {
              let showedUpCount = showedUpCount(for: activeCalendar)
              guard
                let milestone = ShowedUpMilestones.latestMilestone(
                  for: showedUpCount
                )
              else { return }
              router.showScreen(.sheet) { _ in
                MilestoneCelebrationSheet(
                  calendar: activeCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: activeCalendar),
                  kind: .showedUp,
                  dates: renderSnapshot.visibleGridDates,
                  allowsStopShowing: false,
                  showedUpPeriodKey: ShowedUpMilestones.periodKey(for: .allTime)
                )
              }
            },
            onTapShare: {
              router.showScreen(.sheet) { _ in
                CalendarShareSheet(
                  calendar: activeCalendar,
                  year: valuationStore.selectedYear,
                  dates: renderSnapshot.calendarYearGridDates,
                  statsBundle: statsBundle,
                  isPremium: isPremium(customerInfo: customerInfo)
                )
              }
            }
          )
          .id(colorScheme)
          .padding(.top, 20)
        }
      }
      .frame(maxWidth: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .scrollIndicators(.hidden)
    .refreshable {
      store.loadCalendars()
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
    .sheet(isPresented: $isPaywallPresented) {
      PaywallView()
        .onAppear {
          Analytics.shared.trackPaywallViewed(trigger: .statsGate)
        }
    }
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title), message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .onAppear {
      Purchases.shared.getCustomerInfo { info, _ in
        self.customerInfo = info
      }
      today = Calendar.current.startOfDay(for: Date())
    }
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active else { return }
      let newToday = Calendar.current.startOfDay(for: Date())
      if newToday != today {
        today = newToday
      }
    }
    .onChange(of: store.snapshot.dataVersion) { _, _ in
      optimisticEntryOverrides.removeAll()
      if isEntryEditSheetPresented {
        scheduleMilestoneCheck()
      } else {
        evaluateMilestonesIfNeeded(calendarId: calendar.id)
      }
    }
    .task(id: statsTaskId) {
      guard !isStoreLoading else { return }
      let token = renderSnapshot.cacheKey
      let statsToday = today
      let statsCurrentPeriodReferenceDate = renderSnapshot.currentPeriodReferenceDate
      let bundle = await Task.detached(priority: .userInitiated) {
        computeCalendarStatsBundle(
          calendar: activeCalendar,
          year: selectedYear,
          todayLocal: statsToday,
          currentPeriodReferenceDate: statsCurrentPeriodReferenceDate
        )
      }.value
      if token == self.renderSnapshot.cacheKey, !store.snapshot.isLoading {
        statsBundle = bundle
      }
    }
  }

  private var optimisticOverridesSignature: String {
    optimisticEntryOverrides
      .sorted { $0.key < $1.key }
      .map { key, override in
        let entrySignature =
          override.entry.map {
            "\(dayKey(for: $0.date)):\($0.count):\($0.completed)"
          } ?? "nil"
        return "\(key):\(entrySignature)"
      }
      .joined(separator: ",")
  }
}
