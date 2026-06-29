import SharedModels
import SwiftUI

struct OverviewDerivedSnapshotServiceDependencies {
  let cacheStore: CacheStore
  let compute: @Sendable ([CustomCalendar], Int, [Date], Date, Date?) -> OverviewDerivedSnapshot

  static let live = OverviewDerivedSnapshotServiceDependencies(
    cacheStore: .shared,
    compute: { calendars, year, dates, todayLocal, currentPeriodReferenceDate in
      computeOverviewDerivedSnapshot(
        calendars: calendars,
        year: year,
        dates: dates,
        todayLocal: todayLocal,
        currentPeriodReferenceDate: currentPeriodReferenceDate
      )
    }
  )
}

struct OverviewDerivedSnapshot: Codable {
  let statsBundleSnapshot: StatsBundleSnapshot
  let zByDay: [Double]

  var statsBundle: StatsBundle {
    statsBundleSnapshot.toBundle()
  }
}

struct OverviewDerivedInput: Hashable {
  let year: Int
  let dataVersion: Int
  let daySeedKey: String
  let timeZoneIdentifier: String
}

func makeOverviewDerivedInput(year: Int, dataVersion: Int, today: Date) -> OverviewDerivedInput {
  OverviewDerivedInput(
    year: year,
    dataVersion: dataVersion,
    daySeedKey: dayKey(for: LocalDayCalendar.startOfDay(for: today)),
    timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
  )
}

func makeOverviewDerivedCacheKey(_ input: OverviewDerivedInput) -> CacheKey {
  CacheKey(
    scope: .overviewDerivedSnapshot,
    identifier: "v1|\(input.year)|\(input.dataVersion)|\(input.daySeedKey)|\(input.timeZoneIdentifier)"
  )
}

func computeOverviewDerivedSnapshot(
  calendars: [CustomCalendar],
  year: Int,
  dates: [Date],
  todayLocal: Date,
  currentPeriodReferenceDate: Date?
) -> OverviewDerivedSnapshot {
  var cal = Calendar(identifier: .gregorian)
  cal.locale = Locale(identifier: "en_US_POSIX")
  cal.timeZone = .autoupdatingCurrent

  let entriesByCalendarByBucket = buildEntriesByCalendarByBucket(calendars: calendars)
  let q75ByCalendar = counterPercentile75ByCalendar(calendars: calendars)
  let (totalCount, perDayTotal) = aggregateCounts(cal: cal, calendars: calendars)
  let maxCount = perDayTotal.values.max() ?? 0

  let (anySuccessByDay, dayMeanZMap) = buildDailyMaps(
    cal: cal,
    year: year,
    todayLocal: todayLocal,
    calendars: calendars,
    entriesByCalendarByBucket: entriesByCalendarByBucket,
    q75ByCalendar: q75ByCalendar
  )

  let zByDay = dates.map { date in
    guard date <= todayLocal else { return 0.0 }
    return dayMeanZMap[date] ?? 0.0
  }

  let allTimeSuccessDays = buildAllTimeSuccessDays(
    cal: cal,
    todayLocal: todayLocal,
    calendars: calendars
  )
  let activeDays = allTimeSuccessDays.count
  let streaks = computeStreaks(cal: cal, successDays: allTimeSuccessDays, today: todayLocal)

  let currentPeriodCount = currentPeriodReferenceDate.map { referenceDate in
    calendars.reduce(0) { partial, calendar in
      let bucketDate = calendar.bucketDate(for: referenceDate)
      return partial + (entriesByCalendarByBucket[calendar.id]?[bucketDate]?.count ?? 0)
    }
  }

  let rollingStats = computeRollingStats(
    cal: cal,
    todayLocal: todayLocal,
    anySuccessByDay: anySuccessByDay,
    dayMeanZ: dayMeanZMap
  )

  let (weekdayRates, bestWD) = computeWeekdayRates(cal: cal, dayMeanZ: dayMeanZMap)
  let monthlyRates = computeMonthlyRates(cal: cal, year: year, todayLocal: todayLocal, dayMeanZ: dayMeanZMap)
  let volatility = computeWeeklyVolatility(cal: cal, todayLocal: todayLocal, anySuccessByDay: anySuccessByDay)
  let earliestTrackingStart = calendars.map(\.trackingStartedAt).min() ?? todayLocal
  let overviewSeries = buildOverviewStatsPeriodSeries(
    cal: cal,
    startDate: earliestTrackingStart,
    todayLocal: todayLocal,
    anySuccessByDay: anySuccessByDay,
    dayMeanZ: dayMeanZMap
  )
  let currentMissedPeriods = computeCurrentMissedPeriods(from: overviewSeries)
  let averageRecoveryPeriods = computeAverageRecoveryPeriods(from: overviewSeries)

  let statsBundle = StatsBundle(
    basic: CalendarStats(
      activeDays: activeDays,
      totalCount: totalCount,
      maxCount: maxCount,
      longestStreak: streaks.longest,
      currentStreak: streaks.current
    ),
    completionRateTrailingLongWindow: rollingStats.completionRateTrailingLongWindow,
    bestWeekday: bestWD?.day,
    weekdayRates: weekdayRates,
    monthlyRates: monthlyRates,
    averageProgressTrailingShortWindow: rollingStats.averageProgressTrailingShortWindow,
    averageProgressTrailingLongWindow: rollingStats.averageProgressTrailingLongWindow,
    volatilityStd: volatility,
    currentMissedPeriods: currentMissedPeriods,
    averageRecoveryPeriods: averageRecoveryPeriods,
    currentPeriodCount: currentPeriodCount
  )

  return OverviewDerivedSnapshot(
    statsBundleSnapshot: StatsBundleSnapshot(bundle: statsBundle),
    zByDay: zByDay
  )
}

private func buildOverviewStatsPeriodSeries(
  cal: Calendar,
  startDate: Date,
  todayLocal: Date,
  anySuccessByDay: [Date: Bool],
  dayMeanZ: [Date: Double]
) -> CalendarStatsPeriodSeries {
  let currentDay = cal.startOfDay(for: todayLocal)
  var cursor = cal.startOfDay(for: startDate)
  var points: [CalendarStatsPeriodPoint] = []

  while cursor <= currentDay {
    points.append(
      CalendarStatsPeriodPoint(
        date: cursor,
        entry: nil,
        isSuccess: anySuccessByDay[cursor] == true,
        progress: dayMeanZ[cursor] ?? 0,
        isClosed: cursor < currentDay
      )
    )

    guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else {
      break
    }
    cursor = next
  }

  return CalendarStatsPeriodSeries(cadence: .daily, points: points)
}

actor OverviewDerivedSnapshotService {
  static let shared = OverviewDerivedSnapshotService()
  private let dependencies: OverviewDerivedSnapshotServiceDependencies
  private var inFlight: [CacheKey: Task<OverviewDerivedSnapshot?, Never>] = [:]

  init(dependencies: OverviewDerivedSnapshotServiceDependencies = .live) {
    self.dependencies = dependencies
  }

  func snapshot(
    storeSnapshot: CustomCalendarStoreSnapshot,
    year: Int,
    today: Date
  ) async -> OverviewDerivedSnapshot? {
    let input = makeOverviewDerivedInput(year: year, dataVersion: storeSnapshot.dataVersion, today: today)
    let cacheKey = makeOverviewDerivedCacheKey(input)

    if let cached: OverviewDerivedSnapshot = dependencies.cacheStore.get(cacheKey) {
      return cached
    }

    if let cached: OverviewDerivedSnapshot = dependencies.cacheStore.loadDisk(cacheKey) {
      dependencies.cacheStore.set(cacheKey, value: cached)
      return cached
    }

    guard !storeSnapshot.isLoading else { return nil }
    if let task = inFlight[cacheKey] {
      return await task.value
    }

    let calendars = storeSnapshot.calendars
    let dates = getYearDatesArray(for: year)
    let currentPeriodReferenceDate = dates.first { Calendar.current.isDate($0, inSameDayAs: today) }

    let compute = dependencies.compute
    let task = Task.detached(priority: .userInitiated) { () -> OverviewDerivedSnapshot? in
      compute(calendars, year, dates, today, currentPeriodReferenceDate)
    }

    inFlight[cacheKey] = task
    let derived = await task.value
    inFlight[cacheKey] = nil

    if let derived {
      dependencies.cacheStore.set(cacheKey, value: derived)
      dependencies.cacheStore.saveDisk(cacheKey, value: derived)
    }
    return derived
  }
}
