import SharedModels
import Testing

@testable import My_Year

struct CalendarStatisticsDisplayModelTests {
  @Test func usesReadableMetricNamesForPremiumStats() {
    let model = CalendarStatisticsDisplayModel(
      stats: CalendarStats(activeDays: 12, totalCount: 18, maxCount: 4, longestStreak: 6, currentStreak: 2),
      currentPeriodCount: 1,
      unit: nil,
      currencySymbol: nil,
      completionRateTrailingLongWindow: 0.72,
      bestWeekday: 2,
      monthlyRates: [1: 0.2, 2: 0.9, 3: 0.4],
      averageProgressTrailingShortWindow: 0.8,
      averageProgressTrailingLongWindow: 0.6,
      volatilityStdDev: 0.12,
      currentMissedPeriods: 2,
      averageRecoveryPeriods: 1.4,
      isPremium: true,
      cadence: .daily,
      trackingType: .counter
    )

    let titles = model.sections.flatMap(\.metrics).map(\.title)
    let values = model.sections.flatMap(\.metrics).map(\.value)

    #expect(titles.contains("Recent Consistency"))
    #expect(titles.contains("Best Day to Show Up"))
    #expect(titles.contains("Momentum"))
    #expect(titles.contains("Missed"))
    #expect(titles.contains("Recovery"))
    #expect(titles.contains("Strongest Month"))
    #expect(titles.contains("Weakest Month"))
    #expect(values.contains("Improving"))
    #expect(values.contains("Steady"))
    #expect(values.contains("2"))
    #expect(values.contains("1 day"))
    #expect(values.contains(monthName(2)))
    #expect(values.contains(monthName(1)))
    #expect(!titles.contains { $0.contains("Std Dev") || $0.contains("CR") })
  }

  @Test func weeklyCalendarsUseWeeklyWindowsAndHideWeekdayPattern() {
    let model = CalendarStatisticsDisplayModel(
      stats: CalendarStats(activeDays: 4, totalCount: 8, maxCount: 3, longestStreak: 2, currentStreak: 1),
      currentPeriodCount: 2,
      unit: nil,
      currencySymbol: nil,
      completionRateTrailingLongWindow: 0.5,
      bestWeekday: nil,
      monthlyRates: [:],
      averageProgressTrailingShortWindow: 0.3,
      averageProgressTrailingLongWindow: 0.45,
      volatilityStdDev: 0.4,
      currentMissedPeriods: 0,
      averageRecoveryPeriods: nil,
      isPremium: true,
      cadence: .weekly,
      trackingType: .multipleDaily
    )

    let titles = model.sections.flatMap(\.metrics).map(\.title)
    let values = model.sections.flatMap(\.metrics).map(\.value)

    #expect(titles.contains("This Week"))
    #expect(titles.contains("Last 4 Weeks"))
    #expect(titles.contains("Last 12 Weeks"))
    #expect(!titles.contains("Best Day to Show Up"))
    #expect(!titles.contains("Missed"))
    #expect(values.contains("Slipping"))
    #expect(values.contains("Unstable"))
  }
}
