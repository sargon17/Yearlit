import RevenueCat
import SharedModels
import SwiftUI

extension CustomCalendarView {
  func loadCustomerInfo() {
    guard RevenueCatClient.isConfigured else { return }

    Purchases.shared.getCustomerInfo { info, _ in
      self.customerInfo = info
    }
  }

  func handleAppear(activeCalendar: CustomCalendar) {
    loadCustomerInfo()
    today = Calendar.current.startOfDay(for: Date())
    Task {
      await syncAppleHealth(calendar: activeCalendar)
    }
  }

  func handleScenePhaseChange(_ newPhase: ScenePhase, activeCalendar: CustomCalendar) {
    guard newPhase == .active else { return }
    let newToday = Calendar.current.startOfDay(for: Date())
    if newToday != today {
      today = newToday
    }
    Task {
      await syncAppleHealth(calendar: activeCalendar)
    }
  }

  func reloadStatsIfNeeded(
    isStoreLoading: Bool,
    activeCalendar: CustomCalendar,
    selectedYear: Int,
    renderSnapshot: CalendarRenderSnapshot
  ) async {
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
