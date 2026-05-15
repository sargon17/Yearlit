import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftfulRouting
import SwiftUI
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
  @ObservedObject private var valuationStore: ValuationStore = .shared

  @AppStorage("runtimeDebugEnabled") private var runtimeDebugEnabled: Bool = false
  @AppStorage("wandFillForce") private var wandFillForce: Double = 0.5
  @AppStorage(TimelinePreferenceStore.timelineModeKey, store: TimelinePreferenceStore.appGroupDefaults)
  private var timelinePreferenceRawValue: String = ""

  @State private var today: Date = Calendar.current.startOfDay(for: Date())
  @Environment(\.scenePhase) private var scenePhase

  private struct CalendarDisplayState {
    let activeCalendar: CustomCalendar
    let timelineMode: CalendarTimelineMode
    let isShowingYour365: Bool
    let your365Snapshot: Your365Snapshot?
    let calendarYearGridDates: [Date]
    let visibleGridDates: [Date]
    let your365HeaderTitle: String?
    let currentPeriodReferenceDate: Date?
  }

  private var displayState: CalendarDisplayState {
    makeDisplayState(snapshot: store.snapshot, selectedYear: valuationStore.selectedYear)
  }

  private func makeDisplayState(
    snapshot: CustomCalendarStoreSnapshot,
    selectedYear: Int
  ) -> CalendarDisplayState {
    let activeCalendar = snapshot.calendar(id: calendar.id) ?? calendar
    let timelineMode = TimelinePreferenceStore
      .mode(rawValue: timelinePreferenceRawValue)
      .effectiveMode(for: activeCalendar.cadence)
    let isShowingYour365 = activeCalendar.cadence == .daily && timelineMode == .your365
    let calendarYearGridDates = activeCalendar.cadence == .weekly
      ? getYearWeekDatesArray(for: selectedYear)
      : getYearDatesArray(for: selectedYear)
    let your365Snapshot = isShowingYour365
      ? activeCalendar.makeYour365Snapshot(
        completedDates: your365CompletedDates(for: activeCalendar),
        today: today
      )
      : nil
    let visibleGridDates = your365Snapshot?.cells.map(\.date) ?? calendarYearGridDates
    let your365HeaderTitle: String? = {
      guard let snapshot = your365Snapshot else { return nil }
      if activeCalendar.isWithinFirstYear(today: today),
        let todayCell = snapshot.todayCell
      {
        return "Day \(todayCell.dayNumber) of your 365"
      }
      return "Latest 365 days"
    }()
    let currentPeriodReferenceDate: Date? = {
      if isShowingYour365 {
        return your365Snapshot?.todayCell?.date ?? today
      }
      return calendarYearGridDates.first { Calendar.current.isDate($0, inSameDayAs: today) }
    }()

    return CalendarDisplayState(
      activeCalendar: activeCalendar,
      timelineMode: timelineMode,
      isShowingYour365: isShowingYour365,
      your365Snapshot: your365Snapshot,
      calendarYearGridDates: calendarYearGridDates,
      visibleGridDates: visibleGridDates,
      your365HeaderTitle: your365HeaderTitle,
      currentPeriodReferenceDate: currentPeriodReferenceDate
    )
  }

  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?
  @State private var customerInfo: CustomerInfo?
  @State private var isPaywallPresented: Bool = false
  @State private var statsBundle: StatsBundle?
  @State private var statsRefreshToken = UUID()
  @State private var lastObservedDataVersion: Int = 0
  @State private var pendingMilestoneCheck: Bool = false
  @State private var isEntryEditSheetPresented: Bool = false

  private let milestoneCelebrationPolicy = MilestoneCelebrationPolicy.shared

  @Environment(\.router) private var router

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func fillRandomEntries() {
    let state = displayState
    let activeCalendar = state.activeCalendar

    // TODO: Implement clearEntries(calendarId:) in CustomCalendarStore to enable clearing before filling.
    store.clearEntries(calendarId: activeCalendar.id)

    let sourceDates = state.isShowingYour365
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

  private func handleDayTap(_ date: Date) {
    guard !date.isInFuture else { return }

    let activeCalendar = displayState.activeCalendar
    if activeCalendar.trackingType != .binary {
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
    } else if activeCalendar.trackingType == .binary {
      _ = toggleBinaryEntry(calendarId: activeCalendar.id, date: date, calendarStore: store)
      scheduleMilestoneCheck()
    }
    checkIfReachedThreeDays(activeCalendar)
    Task {
      await hapticFeedback()
    }
  }

  private func handleQuickAdd() {
    let state = displayState
    let activeCalendar = state.activeCalendar
    let entryDate = state.currentPeriodReferenceDate ?? Date()
    quickEntry(
      calendar: activeCalendar,
      date: entryDate,
      calendarStore: store
    )

    checkIfReachedThreeDays(activeCalendar)
    scheduleMilestoneCheck()

    Task {
      await hapticFeedback()
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
        dates: displayState.visibleGridDates,
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
      return displayState.calendarYearGridDates
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
    let dataVersion = snapshot.dataVersion
    let selectedYear = valuationStore.selectedYear
    let displayState = makeDisplayState(snapshot: snapshot, selectedYear: selectedYear)
    let activeCalendar = displayState.activeCalendar
    let isStoreLoading = snapshot.isLoading
    let statsTaskId = [
      calendar.id.uuidString,
      "\(selectedYear)",
      "\(dataVersion)",
      isStoreLoading ? "loading" : "hydrated",
      displayState.timelineMode.rawValue,
      statsRefreshToken.uuidString
    ].joined(separator: "|")
    ScrollView {
      VStack(spacing: 10) {
        // Stats header
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(activeCalendar.name.capitalized)
                  .font(.system(size: 36, design: .monospaced))
                  .lineLimit(2)
                  .minimumScaleFactor(0.5)
                  .foregroundColor(Color("text-primary"))
                  .fontWeight(.black)
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

                if My_YearApp.isDebugMode && runtimeDebugEnabled {
                  Button(action: fillRandomEntries) {
                    Image(systemName: "wand.and.stars")
                      .foregroundColor(Color(activeCalendar.color))
                  }
                  .padding(.horizontal, 4)
                }

                let currentYear = Calendar.current.component(.year, from: Date())
                if displayState.isShowingYour365 || valuationStore.selectedYear == currentYear {
                  let quickAddDate = displayState.currentPeriodReferenceDate ?? currentDayDate
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
                if displayState.isShowingYour365 {
                  VStack(alignment: .leading, spacing: 2) {
                    if let title = displayState.your365HeaderTitle {
                      Text(title)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color("text-tertiary"))
                    }
                  }
                } else {
                  Button(action: { showingYearPicker = true }) {
                    Text("\(valuationStore.year.description)")
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                  }

                  Text("•")
                    .font(.system(size: 4, weight: .black, design: .monospaced))
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
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                    Text(reminderTime)
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                  } else {
                    Image(systemName: "bell.slash")
                      .font(.system(size: 12, design: .monospaced))
                      .foregroundColor(Color("text-tertiary"))
                    Text("Off")
                      .font(.system(size: 12, design: .monospaced))
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
          calendar: activeCalendar,
          handleDayTap: handleDayTap,
          dates: displayState.visibleGridDates,
          today: today,
          your365Presentation: displayState.your365Snapshot.map { GridView.Your365Presentation(snapshot: $0) }
        )
        .frame(height: UIScreen.main.bounds.height * 0.55)

        let currentPeriodLogCount: Int? = displayState.currentPeriodReferenceDate.map {
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
                  dates: displayState.visibleGridDates,
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
                  dates: displayState.visibleGridDates,
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
                  dates: displayState.visibleGridDates,
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
      if lastObservedDataVersion != store.snapshot.dataVersion {
        lastObservedDataVersion = store.snapshot.dataVersion
        statsRefreshToken = UUID()
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active else { return }
      let newToday = Calendar.current.startOfDay(for: Date())
      if newToday != today {
        today = newToday
      }
    }
    .onChange(of: store.snapshot.dataVersion) { _, newValue in
      lastObservedDataVersion = newValue
      statsRefreshToken = UUID()
      if isEntryEditSheetPresented {
        scheduleMilestoneCheck()
      } else {
        evaluateMilestonesIfNeeded(calendarId: calendar.id)
      }
    }
    .task(id: statsTaskId) {
      guard !isStoreLoading else { return }
      let token = statsRefreshToken
      let statsToday = today
      let statsCurrentPeriodReferenceDate = displayState.currentPeriodReferenceDate
      let bundle = await Task.detached(priority: .userInitiated) {
        computeCalendarStatsBundle(
          calendar: activeCalendar,
          year: selectedYear,
          todayLocal: statsToday,
          currentPeriodReferenceDate: statsCurrentPeriodReferenceDate
        )
      }.value
      if token == statsRefreshToken, !store.snapshot.isLoading {
        statsBundle = bundle
      }
    }
  }
}
