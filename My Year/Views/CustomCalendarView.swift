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
  @ObservedObject private var valuationStore: ValuationStore = .shared

  @AppStorage("runtimeDebugEnabled") private var runtimeDebugEnabled: Bool = false
  @AppStorage("wandFillForce") private var wandFillForce: Double = 0.5

  private let today = Date()

  private var yearDates: [Date] {
    getYearDatesArray(for: valuationStore.selectedYear)
  }

  private var timelinePreference: CalendarTimelineMode {
    TimelinePreferenceStore.mode().effectiveMode(for: activeCalendar.cadence)
  }

  private var isShowingYour365: Bool {
    activeCalendar.cadence == .daily && timelinePreference == .your365
  }

  private var your365Snapshot: Your365Snapshot? {
    guard isShowingYour365 else { return nil }
    return activeCalendar.makeYour365Snapshot(
      completedDates: completedEntryDates,
      today: today
    )
  }

  private var isYour365FirstYear: Bool {
    guard isShowingYour365 else { return false }

    let trackingStart = LocalDayCalendar.startOfDay(for: activeCalendar.trackingStartedAt)
    let todayStart = LocalDayCalendar.startOfDay(for: today)
    guard let maturityBoundary = LocalDayCalendar.calendar.date(byAdding: .day, value: 364, to: trackingStart) else {
      return false
    }

    return todayStart <= maturityBoundary
  }

  private var visibleGridDates: [Date] {
    if activeCalendar.cadence == .weekly {
      return getYearWeekDatesArray(for: valuationStore.selectedYear)
    }

    if let snapshot = your365Snapshot {
      return snapshot.cells.map(\.date)
    }

    return yearDates
  }

  private var calendarYearGridDates: [Date] {
    if activeCalendar.cadence == .weekly {
      return getYearWeekDatesArray(for: valuationStore.selectedYear)
    }
    return yearDates
  }

  private var completedEntryDates: Set<Date> {
    your365CompletedDates(for: activeCalendar)
  }

  private var your365HeaderTitle: String? {
    makeYour365HeaderTitle(snapshot: your365Snapshot, calendar: activeCalendar)
  }

  private func makeYour365HeaderTitle(snapshot: Your365Snapshot?, calendar: CustomCalendar) -> String? {
    guard let snapshot else { return nil }

    let trackingStart = LocalDayCalendar.startOfDay(for: calendar.trackingStartedAt)
    let todayStart = LocalDayCalendar.startOfDay(for: today)
    let maturityBoundary = LocalDayCalendar.calendar.date(byAdding: .day, value: 364, to: trackingStart)
    if let maturityBoundary,
      todayStart <= maturityBoundary,
      let todayCell = snapshot.cells.first(where: { LocalDayCalendar.calendar.isDate($0.date, inSameDayAs: today) })
    {
      return "Day \(todayCell.dayNumber) of your 365"
    }
    return "Latest 365 days"
  }

  private var currentPeriodReferenceDate: Date? {
    if isShowingYour365 {
      return your365Snapshot?.cells.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.date
        ?? today
    }

    return calendarYearGridDates.first { Calendar.current.isDate($0, inSameDayAs: today) }
  }

  private var activeCalendar: CustomCalendar {
    store.snapshot.calendar(id: calendar.id) ?? calendar
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
    // TODO: Implement clearEntries(calendarId:) in CustomCalendarStore to enable clearing before filling.
    store.clearEntries(calendarId: activeCalendar.id)

    let sourceDates: [Date]
    if activeCalendar.cadence == .weekly {
      sourceDates = getYearWeekDatesArray(for: valuationStore.selectedYear)
    } else if isShowingYour365 {
      sourceDates = your365Snapshot?.cells.map(\.date) ?? []
    } else {
      sourceDates = calendarYearGridDates
    }

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
    let entryDate = currentPeriodReferenceDate ?? Date()
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
        dates: calendarYearGridDates,
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
      return calendarYearGridDates
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
    let statsTaskId =
      "\(calendar.id.uuidString)|\(selectedYear)|\(dataVersion)|\(statsRefreshToken.uuidString)"
    let resolvedCalendar = activeCalendar
    let resolvedIsShowingYour365 = resolvedCalendar.cadence == .daily
      && TimelinePreferenceStore.mode().effectiveMode(for: resolvedCalendar.cadence) == .your365
    let resolvedCompletedEntryDates = resolvedIsShowingYour365 ? your365CompletedDates(for: resolvedCalendar) : Set<Date>()
    let resolvedYour365Snapshot = resolvedIsShowingYour365
      ? resolvedCalendar.makeYour365Snapshot(completedDates: resolvedCompletedEntryDates, today: today)
      : nil
    let resolvedCalendarYearGridDates = resolvedCalendar.cadence == .weekly
      ? getYearWeekDatesArray(for: selectedYear)
      : yearDates
    let resolvedVisibleGridDates = resolvedYour365Snapshot?.cells.map(\.date) ?? resolvedCalendarYearGridDates
    let resolvedCurrentPeriodReferenceDate = resolvedYour365Snapshot?.cells.first {
      Calendar.current.isDate($0.date, inSameDayAs: today)
    }?.date ?? resolvedCalendarYearGridDates.first {
      Calendar.current.isDate($0, inSameDayAs: today)
    }
    let resolvedYour365HeaderTitle = makeYour365HeaderTitle(
      snapshot: resolvedYour365Snapshot,
      calendar: resolvedCalendar
    )

    ScrollView {
      VStack(spacing: 10) {
        // Stats header
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(resolvedCalendar.name.capitalized)
                  .font(.system(size: 36, design: .monospaced))
                  .lineLimit(2)
                  .minimumScaleFactor(0.5)
                  .foregroundColor(Color("text-primary"))
                  .fontWeight(.black)
                  .onTapGesture {
                    router.showScreen(.sheet) { _ in
                      EditCalendarView(
                        calendar: resolvedCalendar,
                        onSave: { updatedCalendar in
                          store.updateCalendar(updatedCalendar)
                        },
                        onDelete: { _ in
                          store.deleteCalendar(id: resolvedCalendar.id)
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
                      .foregroundColor(Color(resolvedCalendar.color))
                  }
                  .padding(.horizontal, 4)
                }

                let currentYear = Calendar.current.component(.year, from: Date())
                if resolvedIsShowingYour365 || valuationStore.selectedYear == currentYear {
                  let quickAddDate = resolvedCurrentPeriodReferenceDate ?? today
                  let isCompletedToday =
                    store.getEntry(
                      calendarId: resolvedCalendar.id,
                      date: quickAddDate
                    )?.completed == true
                  Button(action: {
                    handleQuickAdd()
                  }) {
                    ZStack {
                      RoundedRectangle(cornerRadius: 3)
                        .fill(Color(resolvedCalendar.color).opacity(0.1))
                        .frame(width: 20, height: 20)

                      Image(
                        systemName: resolvedCalendar.trackingType == .binary
                          && isCompletedToday
                          ? "minus" : "plus"
                      )
                      .font(.system(size: 16))
                      .foregroundColor(Color(resolvedCalendar.color))
                    }
                  }.frame(width: 24, height: 24)
                }
              }

              HStack(spacing: 4) {
                if resolvedIsShowingYour365 {
                  VStack(alignment: .leading, spacing: 2) {
                    if let title = resolvedYour365HeaderTitle {
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
                  if resolvedCalendar.recurringReminderEnabled,
                    let hour = resolvedCalendar.reminderHour,
                    let minute = resolvedCalendar.reminderMinute
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
                      calendar: resolvedCalendar,
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
          calendar: resolvedCalendar,
          store: store,
          handleDayTap: handleDayTap,
          dates: resolvedVisibleGridDates,
          year: valuationStore.selectedYear,
          your365Presentation: resolvedYour365Snapshot.map { GridView.Your365Presentation(snapshot: $0) }
        )
        .frame(height: UIScreen.main.bounds.height * 0.55)

        let currentPeriodLogCount: Int? = resolvedCurrentPeriodReferenceDate.map {
          entry(for: resolvedCalendar, date: $0)?.count ?? 0
        }

        if let bundle = statsBundle {
          CalendarStatisticsView(
            stats: bundle.basic,
            accentColor: Color(resolvedCalendar.color),
            currentPeriodCount: currentPeriodLogCount,
            unit: resolvedCalendar.unit,
            currencySymbol: resolvedCalendar.currencySymbol,
            completionRateTrailingLongWindow: bundle.completionRateTrailingLongWindow,
            bestWeekday: bundle.bestWeekday,
            weekdayRates: bundle.weekdayRates,
            monthlyRates: bundle.monthlyRates,
            averageProgressTrailingShortWindow: bundle.averageProgressTrailingShortWindow,
            averageProgressTrailingLongWindow: bundle.averageProgressTrailingLongWindow,
            volatilityStdDev: bundle.volatilityStd,
            isPremium: isPremium(customerInfo: customerInfo),
            onUpgrade: { isPaywallPresented = true },
            cadence: resolvedCalendar.cadence,
            trackingType: resolvedCalendar.trackingType,
            onTapCurrentStreak: {
              guard
                let milestone = StreakMilestones.latestMilestone(
                  for: currentStreak(for: resolvedCalendar)
                )
              else { return }
              router.showScreen(.sheet) { _ in
                MilestoneCelebrationSheet(
                  calendar: resolvedCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: resolvedCalendar),
                  kind: .streak,
                  dates: calendarYearGridDates,
                  allowsStopShowing: false,
                  showedUpPeriodKey: nil
                )
              }
            },
            onTapActiveDays: {
              let showedUpCount = showedUpCount(for: resolvedCalendar)
              guard
                let milestone = ShowedUpMilestones.latestMilestone(
                  for: showedUpCount
                )
              else { return }
              router.showScreen(.sheet) { _ in
                MilestoneCelebrationSheet(
                  calendar: resolvedCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: resolvedCalendar),
                  kind: .showedUp,
                  dates: calendarYearGridDates,
                  allowsStopShowing: false,
                  showedUpPeriodKey: ShowedUpMilestones.periodKey(for: .allTime)
                )
              }
            },
            onTapShare: {
              router.showScreen(.sheet) { _ in
                CalendarShareSheet(
                  calendar: resolvedCalendar,
                  year: valuationStore.selectedYear,
                  dates: calendarYearGridDates,
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
      if lastObservedDataVersion != store.snapshot.dataVersion {
        lastObservedDataVersion = store.snapshot.dataVersion
        statsRefreshToken = UUID()
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
      let token = statsRefreshToken
      let bundle = await Task.detached(priority: .userInitiated) {
        computeCalendarStatsBundle(
          calendar: resolvedCalendar,
          year: selectedYear,
          todayLocal: today,
          currentPeriodReferenceDate: resolvedCurrentPeriodReferenceDate
        )
      }.value
      if token == statsRefreshToken {
        statsBundle = bundle
      }
    }
  }
}

enum CalendarError: LocalizedError, Identifiable {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)

  var id: String {
    localizedDescription
  }

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
