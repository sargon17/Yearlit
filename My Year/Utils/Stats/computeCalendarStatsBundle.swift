import SharedModels
import SwiftUI

func computeCalendarStatsBundle(
  calendar: CustomCalendar,
  year: Int,
  todayLocal: Date,
  currentPeriodReferenceDate: Date?
) -> StatsBundle {
  let cal = LocalDayCalendar.calendar
  let entriesByBucket = buildEntriesByCalendarByBucket(calendars: [calendar])
  let bucketedEntries = entriesByBucket[calendar.id] ?? [:]
  let q75 = counterPercentile75ByCalendar(calendars: [calendar])[calendar.id]
  let basic = computeBasicCalendarStats(for: calendar, today: todayLocal, bucketedEntries: bucketedEntries)
  let series = buildCalendarStatsPeriodSeries(
    CalendarStatsPeriodSeriesInput(
      cal: cal,
      calendar: calendar,
      entriesByBucket: bucketedEntries,
      q75: q75,
      startDate: calendar.trackingStartedAt,
      todayLocal: todayLocal
    )
  )

  func entryOn(_ date: Date) -> CalendarEntry? {
    entry(for: calendar, date: date, entriesByCalendarByBucket: entriesByBucket)
  }

  let trendStats = computeCalendarTrendStats(
    cal: cal,
    calendar: calendar,
    year: year,
    todayLocal: todayLocal,
    series: series
  )

  let currentPeriodCount = currentPeriodReferenceDate.map { entryOn($0)?.count ?? 0 }

  return StatsBundle(
    basic: basic,
    completionRateTrailingLongWindow: trendStats.rolling.completionRateTrailingLongWindow,
    bestWeekday: trendStats.bestWeekday,
    weekdayRates: trendStats.weekdayRates,
    monthlyRates: trendStats.monthlyRates,
    averageProgressTrailingShortWindow: trendStats.rolling.averageProgressTrailingShortWindow,
    averageProgressTrailingLongWindow: trendStats.rolling.averageProgressTrailingLongWindow,
    volatilityStd: trendStats.volatility,
    currentMissedPeriods: trendStats.currentMissedPeriods,
    averageRecoveryPeriods: trendStats.averageRecoveryPeriods,
    currentPeriodCount: currentPeriodCount
  )
}

private struct CalendarTrendStats {
  let rolling: RollingStats
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let monthlyRates: [Int: Double]
  let volatility: Double
  let currentMissedPeriods: Int
  let averageRecoveryPeriods: Double?
}

private func computeCalendarTrendStats(
  cal: Calendar,
  calendar: CustomCalendar,
  year: Int,
  todayLocal: Date,
  series: CalendarStatsPeriodSeries
) -> CalendarTrendStats {
  let weekday =
    calendar.cadence == .daily
    ? computeWeekdayRates(cal: cal, year: year, todayLocal: todayLocal, series: series, normalizeToMax: true)
    : (weekdayRates: [:], best: nil)

  return CalendarTrendStats(
    rolling: computeRollingStats(from: series),
    bestWeekday: weekday.best?.day,
    weekdayRates: weekday.weekdayRates,
    monthlyRates: computeMonthlyRates(
      cal: cal,
      year: year,
      trackingType: calendar.trackingType,
      series: series
    ),
    volatility: computeVolatility(cal: cal, todayLocal: todayLocal, series: series),
    currentMissedPeriods: computeCurrentMissedPeriods(from: series),
    averageRecoveryPeriods: computeAverageRecoveryPeriods(from: series)
  )
}

private func computeBasicCalendarStats(
  for calendar: CustomCalendar,
  today: Date,
  bucketedEntries: [Date: CalendarEntry]
) -> CalendarStats {
  let activeDays = bucketedEntries.values.filter { entry in
    switch calendar.trackingType {
    case .binary:
      return entry.completed
    case .counter, .multipleDaily:
      return entry.hasLoggedCount
    }
  }.count

  let totalCount = bucketedEntries.values.reduce(0) { $0 + $1.count }
  let maxCount = bucketedEntries.values.map { $0.count }.max() ?? 0
  let localCalendar = LocalDayCalendar.calendar
  let longestStreak = WidgetStreak.longestStreak(calendar: calendar, calendarSystem: localCalendar)
  let currentStreak = WidgetStreak.currentStreak(
    calendar: calendar,
    today: today,
    calendarSystem: localCalendar
  ).streak

  return CalendarStats(
    activeDays: activeDays,
    totalCount: totalCount,
    maxCount: maxCount,
    longestStreak: longestStreak,
    currentStreak: currentStreak
  )
}
