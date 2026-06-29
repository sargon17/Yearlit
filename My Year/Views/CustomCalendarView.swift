import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CustomCalendarView: View {
  @Environment(\.colorScheme) var colorScheme
  let calendar: CustomCalendar
  @StateObject var store: CustomCalendarStore = .shared
  @ObservedObject var timelinePreference = TimelinePreferenceManager.shared
  @ObservedObject var valuationStore: ValuationStore = .shared

  @AppStorage(AppStorageKeys.runtimeDebugEnabled) var runtimeDebugEnabled: Bool = false
  @AppStorage(AppStorageKeys.cleanScreenshotsEnabled) var cleanScreenshotsEnabled: Bool = false
  @AppStorage(AppStorageKeys.wandFillForce) var wandFillForce: Double = 0.5
  @State var today: Date = Calendar.current.startOfDay(for: Date())
  @Environment(\.scenePhase) private var scenePhase

  var renderSnapshot: CalendarRenderSnapshot {
    makeRenderSnapshot(snapshot: store.snapshot, selectedYear: valuationStore.selectedYear)
  }

  func makeRenderSnapshot(
    snapshot: CustomCalendarStoreSnapshot,
    selectedYear: Int
  ) -> CalendarRenderSnapshot {
    let activeCalendar = CustomCalendarOptimisticEntries.applying(
      optimisticEntryOverrides,
      to: snapshot.calendar(id: calendar.id) ?? calendar
    )
    return CalendarRenderSnapshotCache.snapshot(CalendarRenderSnapshotInput(
      calendar: activeCalendar,
      selectedYear: selectedYear,
      timelineMode: timelinePreference.mode,
      today: today,
      colorScheme: colorScheme,
      optimisticOverridesSignature: optimisticOverridesSignature
    ))
  }

  @State var showingYearPicker: Bool = false
  @State var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State var calendarError: CalendarError?
  @State var customerInfo: CustomerInfo?
  @State var isPaywallPresented: Bool = false
  @State var statsBundle: StatsBundle?
  @State var pendingMilestoneCheck: Bool = false
  @State var isEntryEditSheetPresented: Bool = false
  @State var optimisticEntryOverrides: [String: CustomCalendarOptimisticEntryOverride] = [:]
  @State var isSyncingAppleHealth: Bool = false
  @State var checkInRippleTrigger: Int = 0
  @State var checkInRippleOriginDate: Date?

  let milestoneCelebrationPolicy = MilestoneCelebrationPolicy.shared
  let appleHealthSyncService = AppleHealthCalendarSyncService()

  var shouldShowDeveloperControls: Bool {
    !cleanScreenshotsEnabled
      && My_YearApp.isDebugMode
      && runtimeDebugEnabled
  }

  func canShowAppleHealthDebugControls(for calendar: CustomCalendar) -> Bool {
    calendar.isAppleHealthConnected && shouldShowDeveloperControls
  }

  @Environment(\.router) var router

  let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()
}

extension CustomCalendarView {
  @ViewBuilder
  var body: some View {
    let snapshot = store.snapshot
    let selectedYear = valuationStore.selectedYear
    let renderSnapshot = makeRenderSnapshot(snapshot: snapshot, selectedYear: selectedYear)
    let activeCalendar = renderSnapshot.activeCalendar
    let isStoreLoading = snapshot.isLoading
    let quickAddDate = renderSnapshot.currentPeriodReferenceDate
    let isCurrentPeriodCompleted =
      quickAddDate.flatMap {
        store.getEntry(
          calendarId: activeCalendar.id,
          date: $0
        )
      }?.completed == true
    let currentPeriodLogCount: Int? = renderSnapshot.currentPeriodReferenceDate.map {
      entry(for: activeCalendar, date: $0)?.count ?? 0
    }
    let statsTaskId = [
      renderSnapshot.cacheKey,
      isStoreLoading ? "loading" : "hydrated"
    ].joined(separator: "|")
    ScrollView {
      CustomCalendarContentView(
        activeCalendar: activeCalendar,
        renderSnapshot: renderSnapshot,
        yearText: valuationStore.year.description,
        selectedYear: selectedYear,
        isCurrentPeriodCompleted: isCurrentPeriodCompleted,
        quickAddDate: quickAddDate,
        showsDeveloperControls: shouldShowDeveloperControls,
        showsAppleHealthDebugControls: canShowAppleHealthDebugControls(for: activeCalendar),
        isSyncingAppleHealth: isSyncingAppleHealth,
        checkInRippleOriginDate: checkInRippleOriginDate,
        checkInRippleTrigger: checkInRippleTrigger,
        statsBundle: statsBundle,
        currentPeriodLogCount: currentPeriodLogCount,
        customerInfo: customerInfo,
        colorScheme: colorScheme,
        onEdit: { presentEditCalendar(activeCalendar) },
        onFillRandomEntries: fillRandomEntries,
        onQuickAdd: handleQuickAdd,
        onShowYearPicker: { showingYearPicker = true },
        onNotificationSettings: { presentNotificationSettings(for: activeCalendar) },
        onAppleHealthDebugSync: {
          Task {
            await syncAppleHealth(calendar: activeCalendar, showsErrors: true)
          }
        },
        onDayTap: handleDayTap,
        onCheckIn: { date in presentEntryEditSheet(calendar: activeCalendar, date: date) },
        onUpgrade: { isPaywallPresented = true },
        onShare: { presentCalendarShareSheet(calendar: activeCalendar, renderSnapshot: renderSnapshot) }
      )
    }
    .scrollIndicators(.hidden)
    .refreshable {
      store.loadCalendars()
    }
    .sheet(isPresented: $showingYearPicker) {
      CustomCalendarYearPickerSheet(
        isPresented: $showingYearPicker,
        selectedYear: $valuationStore.selectedYear,
        tempSelectedYear: $tempSelectedYear,
        availableYears: availableYears
      )
    }
    .sheet(isPresented: $isPaywallPresented) {
      PremiumPaywallSheet(trigger: .statsGate)
    }
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title), message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .onAppear {
      handleAppear(activeCalendar: renderSnapshot.activeCalendar)
    }
    .onChange(of: scenePhase) { _, newPhase in
      handleScenePhaseChange(newPhase, activeCalendar: renderSnapshot.activeCalendar)
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
      await reloadStatsIfNeeded(
        isStoreLoading: isStoreLoading,
        activeCalendar: activeCalendar,
        selectedYear: selectedYear,
        renderSnapshot: renderSnapshot
      )
    }
  }

  private var optimisticOverridesSignature: String {
    CustomCalendarOptimisticEntries.signature(optimisticEntryOverrides)
  }

}
