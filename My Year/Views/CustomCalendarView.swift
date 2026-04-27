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

  private var gridDates: [Date] {
    activeCalendar.cadence == .weekly
      ? getYearWeekDatesArray(for: valuationStore.selectedYear)
      : yearDates
  }

  private var currentPeriodReferenceDate: Date? {
    yearDates.first { Calendar.current.isDate($0, inSameDayAs: Date()) }
  }

  private var activeCalendar: CustomCalendar {
    store.snapshot.calendar(id: calendar.id) ?? calendar
  }

  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?
  @EnvironmentObject private var entitlements: EntitlementManager
  @State private var isPaywallPresented: Bool = false
  @StateObject private var statsLoader = CalendarStatsLoader()
  @State private var statsRefreshToken = UUID()
  @State private var lastObservedDataVersion: Int = 0
  @State private var pendingMilestoneCheck: Bool = false
  @State private var isEntryEditSheetPresented: Bool = false
  @State private var isMilestoneDebugDialogPresented: Bool = false

  @Environment(\.router) private var router

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private let milestoneService = MilestoneCelebrationService()
  private let debugFillService = CalendarDebugFillService()

  private func fillRandomEntries() {
    debugFillService.fillRandomEntries(
      calendar: activeCalendar,
      selectedYear: valuationStore.selectedYear,
      currentDayNumber: valuationStore.currentDayNumber,
      force: wandFillForce,
      store: store,
      today: today
    )
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
    guard let updatedCalendar = store.snapshot.calendar(id: calendarId) else { return }

    if let celebration = milestoneService.celebrationIfNeeded(
      calendar: updatedCalendar,
      calendarId: calendarId,
      gridDates: gridDates
    ) {
      presentMilestone(celebration)
    }
  }

  private func showDebugMilestonePreview(kind: MilestoneKind, calendar: CustomCalendar) {
    guard
      let celebration = milestoneService.debugPreview(
        kind: kind,
        calendar: calendar,
        gridDates: gridDates
      )
    else { return }

    presentMilestone(celebration)
  }

  private func presentMilestone(_ celebration: MilestoneCelebration) {
    router.showScreen(.sheet) { _ in
      StreakMilestoneShareSheet(
        calendar: celebration.calendar,
        milestone: celebration.milestone,
        currentStreak: celebration.currentStreak,
        kind: celebration.kind,
        dates: celebration.dates,
        isPreview: celebration.isPreview
      )
    }
  }

  private func currentStreak(for calendar: CustomCalendar) -> Int {
    milestoneService.currentStreak(for: calendar)
  }

  private func showedUpCount(for calendar: CustomCalendar) -> Int {
    milestoneService.showedUpCount(for: calendar)
  }

  var body: some View {
    let snapshot = store.snapshot
    let dataVersion = snapshot.dataVersion
    let selectedYear = valuationStore.selectedYear
    let isCurrentYearSelected = selectedYear == Calendar.current.component(.year, from: Date())
    let statsTaskId =
      "\(calendar.id.uuidString)|\(selectedYear)|\(dataVersion)|\(statsRefreshToken.uuidString)"
    let resolvedCalendar = activeCalendar
    let resolvedCurrentPeriodReferenceDate = currentPeriodReferenceDate

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

                  Button(action: { isMilestoneDebugDialogPresented = true }) {
                    Image(systemName: "testtube.2")
                      .foregroundColor(Color(resolvedCalendar.color))
                  }
                  .padding(.horizontal, 4)
                }

                if valuationStore.selectedYear == Calendar.current.component(.year, from: Date()) {
                  let isCompletedToday = store.getEntry(calendarId: resolvedCalendar.id, date: today)?.completed == true
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
                Button(action: { showingYearPicker = true }) {
                  Text("\(valuationStore.year.description)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                }

                Text("•")
                  .font(.system(size: 4, weight: .black, design: .monospaced))
                  .foregroundColor(Color("text-tertiary"))
                  .padding(.horizontal, 2)

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
                      isPremiumUser: entitlements.isPremium,
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
          dates: gridDates,
          year: valuationStore.selectedYear
        )
        .frame(height: UIScreen.main.bounds.height * 0.55)

        let currentPeriodLogCount: Int? = resolvedCurrentPeriodReferenceDate.map {
          entry(for: resolvedCalendar, date: $0)?.count ?? 0
        }

        if let bundle = statsLoader.bundle {
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
            isPremium: entitlements.isPremium,
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
                StreakMilestoneShareSheet(
                  calendar: resolvedCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: resolvedCalendar),
                  kind: .streak,
                  dates: gridDates
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
                StreakMilestoneShareSheet(
                  calendar: resolvedCalendar,
                  milestone: milestone,
                  currentStreak: currentStreak(for: resolvedCalendar),
                  kind: .showedUp,
                  dates: gridDates
                )
              }
            },
            onTapShare: {
              router.showScreen(.sheet) { _ in
                CalendarShareSheet(
                  calendar: resolvedCalendar,
                  year: valuationStore.selectedYear,
                  dates: gridDates,
                  statsBundle: statsLoader.bundle,
                  isPremium: entitlements.isPremium
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
      EntitlementRefreshingPaywallView()
    }
    .confirmationDialog(
      "Preview milestone",
      isPresented: $isMilestoneDebugDialogPresented,
      titleVisibility: .visible
    ) {
      Button("Preview next streak milestone") {
        showDebugMilestonePreview(kind: .streak, calendar: activeCalendar)
      }
      if isCurrentYearSelected,
        activeCalendar.cadence == .daily,
        ShowedUpMilestones.nextMilestone(
          after: ShowedUpMilestones.showedUpCount(for: activeCalendar, kind: .currentMonth),
          kind: .currentMonth
        ) != nil
      {
        Button("Preview next showed up this month milestone") {
          showDebugMilestonePreview(kind: .showedUpMonth, calendar: activeCalendar)
        }
      }
      if isCurrentYearSelected,
        activeCalendar.cadence == .daily,
        ShowedUpMilestones.nextMilestone(
          after: ShowedUpMilestones.showedUpCount(for: activeCalendar, kind: .currentYear),
          kind: .currentYear
        ) != nil
      {
        Button("Preview next showed up this year milestone") {
          showDebugMilestonePreview(kind: .showedUpYear, calendar: activeCalendar)
        }
      }
      Button("Preview next showed up all-time milestone") {
        showDebugMilestonePreview(kind: .showedUp, calendar: activeCalendar)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Debug only. Opens the milestone sheet without changing tracker state.")
    }
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title), message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .onAppear {
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
    .onDisappear {
      statsLoader.cancel()
    }
    .task(id: statsTaskId) {
      statsLoader.load(
        calendar: resolvedCalendar,
        year: selectedYear,
        currentPeriodReferenceDate: resolvedCurrentPeriodReferenceDate
      )
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
