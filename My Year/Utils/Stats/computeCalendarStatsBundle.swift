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
    cal: cal,
    calendar: calendar,
    entriesByBucket: bucketedEntries,
    q75: q75,
    startDate: calendar.trackingStartedAt,
    todayLocal: todayLocal
  )

  func entryOn(_ date: Date) -> CalendarEntry? {
    entry(for: calendar, date: date, entriesByCalendarByBucket: entriesByBucket)
  }

  let rollingStats: (cr30: Double, avg7: Double, avg30: Double)
  let monthly: [Int: Double]
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let volatility: Double
  let currentMissedPeriods: Int
  let averageRecoveryPeriods: Double?

  switch calendar.cadence {
  case .daily:
    rollingStats = computeRollingStats(from: series)
    let weekday = computeWeekdayRates(
      cal: cal,
      year: year,
      todayLocal: todayLocal,
      series: series,
      normalizeToMax: true
    )
    bestWeekday = weekday.best?.day
    weekdayRates = weekday.weekdayRates
    monthly = computeMonthlyRates(
      cal: cal,
      year: year,
      todayLocal: todayLocal,
      trackingType: calendar.trackingType,
      series: series
    )
    volatility = computeVolatility(cal: cal, todayLocal: todayLocal, series: series)
    currentMissedPeriods = computeCurrentMissedPeriods(from: series)
    averageRecoveryPeriods = computeAverageRecoveryPeriods(from: series)
  case .weekly:
    rollingStats = computeRollingStats(from: series)
    bestWeekday = nil
    weekdayRates = [:]
    monthly = computeMonthlyRates(
      cal: cal,
      year: year,
      todayLocal: todayLocal,
      trackingType: calendar.trackingType,
      series: series
    )
    volatility = computeVolatility(cal: cal, todayLocal: todayLocal, series: series)
    currentMissedPeriods = computeCurrentMissedPeriods(from: series)
    averageRecoveryPeriods = computeAverageRecoveryPeriods(from: series)
  }

  let currentPeriodCount = currentPeriodReferenceDate.map { entryOn($0)?.count ?? 0 }

  return StatsBundle(
    basic: basic,
    completionRateTrailingLongWindow: rollingStats.cr30,
    bestWeekday: bestWeekday,
    weekdayRates: weekdayRates,
    monthlyRates: monthly,
    averageProgressTrailingShortWindow: rollingStats.avg7,
    averageProgressTrailingLongWindow: rollingStats.avg30,
    volatilityStd: volatility,
    currentMissedPeriods: currentMissedPeriods,
    averageRecoveryPeriods: averageRecoveryPeriods,
    currentPeriodCount: currentPeriodCount
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
      return entry.count > 0
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
