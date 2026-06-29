import RevenueCat
import SharedModels
import SwiftUI

struct CustomCalendarStatsSection: View {
  let bundle: StatsBundle
  let calendar: CustomCalendar
  let colorScheme: ColorScheme
  let currentPeriodLogCount: Int?
  let customerInfo: CustomerInfo?
  let onUpgrade: () -> Void
  let onShare: () -> Void

  var body: some View {
    CalendarStatisticsView(
      stats: bundle.basic,
      accentColor: Color(calendar.color),
      currentPeriodCount: currentPeriodLogCount,
      unit: calendar.unit,
      currencySymbol: calendar.currencySymbol,
      completionRateTrailingLongWindow: bundle.completionRateTrailingLongWindow,
      bestWeekday: bundle.bestWeekday,
      weekdayRates: bundle.weekdayRates,
      monthlyRates: bundle.monthlyRates,
      averageProgressTrailingShortWindow: bundle.averageProgressTrailingShortWindow,
      averageProgressTrailingLongWindow: bundle.averageProgressTrailingLongWindow,
      volatilityStdDev: bundle.volatilityStd,
      currentMissedPeriods: bundle.currentMissedPeriods,
      averageRecoveryPeriods: bundle.averageRecoveryPeriods,
      isPremium: isPremium(customerInfo: customerInfo),
      onUpgrade: onUpgrade,
      cadence: calendar.cadence,
      trackingType: calendar.trackingType,
      onTapShare: onShare
    )
    .id(colorScheme)
    .padding(.top, 20)
  }
}
