struct CalendarStatsSnapshot: Codable {
  let activeDays: Int
  let totalCount: Int
  let maxCount: Int
  let longestStreak: Int
  let currentStreak: Int

  init(stats: CalendarStats) {
    activeDays = stats.activeDays
    totalCount = stats.totalCount
    maxCount = stats.maxCount
    longestStreak = stats.longestStreak
    currentStreak = stats.currentStreak
  }

  func toStats() -> CalendarStats {
    CalendarStats(
      activeDays: activeDays,
      totalCount: totalCount,
      maxCount: maxCount,
      longestStreak: longestStreak,
      currentStreak: currentStreak
    )
  }
}

struct StatsBundleSnapshot: Codable {
  let basic: CalendarStatsSnapshot
  let completionRateTrailingLongWindow: Double
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let monthlyRates: [Int: Double]
  let averageProgressTrailingShortWindow: Double
  let averageProgressTrailingLongWindow: Double
  let volatilityStd: Double
  let currentMissedPeriods: Int
  let averageRecoveryPeriods: Double?
  let currentPeriodCount: Int?

  init(bundle: StatsBundle) {
    basic = CalendarStatsSnapshot(stats: bundle.basic)
    completionRateTrailingLongWindow = bundle.completionRateTrailingLongWindow
    bestWeekday = bundle.bestWeekday
    weekdayRates = bundle.weekdayRates
    monthlyRates = bundle.monthlyRates
    averageProgressTrailingShortWindow = bundle.averageProgressTrailingShortWindow
    averageProgressTrailingLongWindow = bundle.averageProgressTrailingLongWindow
    volatilityStd = bundle.volatilityStd
    currentMissedPeriods = bundle.currentMissedPeriods
    averageRecoveryPeriods = bundle.averageRecoveryPeriods
    currentPeriodCount = bundle.currentPeriodCount
  }

  enum CodingKeys: String, CodingKey {
    case basic
    case completionRateTrailingLongWindow
    case bestWeekday
    case weekdayRates
    case monthlyRates
    case averageProgressTrailingShortWindow
    case averageProgressTrailingLongWindow
    case volatilityStd
    case currentMissedPeriods
    case averageRecoveryPeriods
    case currentPeriodCount
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    basic = try container.decode(CalendarStatsSnapshot.self, forKey: .basic)
    completionRateTrailingLongWindow = try container.decode(Double.self, forKey: .completionRateTrailingLongWindow)
    bestWeekday = try container.decodeIfPresent(Int.self, forKey: .bestWeekday)
    weekdayRates = try container.decode([Int: Double].self, forKey: .weekdayRates)
    monthlyRates = try container.decode([Int: Double].self, forKey: .monthlyRates)
    averageProgressTrailingShortWindow = try container.decode(
      Double.self,
      forKey: .averageProgressTrailingShortWindow
    )
    averageProgressTrailingLongWindow = try container.decode(Double.self, forKey: .averageProgressTrailingLongWindow)
    volatilityStd = try container.decode(Double.self, forKey: .volatilityStd)
    currentMissedPeriods = try container.decodeIfPresent(Int.self, forKey: .currentMissedPeriods) ?? 0
    averageRecoveryPeriods = try container.decodeIfPresent(Double.self, forKey: .averageRecoveryPeriods)
    currentPeriodCount = try container.decodeIfPresent(Int.self, forKey: .currentPeriodCount)
  }

  func toBundle() -> StatsBundle {
    StatsBundle(
      basic: basic.toStats(),
      completionRateTrailingLongWindow: completionRateTrailingLongWindow,
      bestWeekday: bestWeekday,
      weekdayRates: weekdayRates,
      monthlyRates: monthlyRates,
      averageProgressTrailingShortWindow: averageProgressTrailingShortWindow,
      averageProgressTrailingLongWindow: averageProgressTrailingLongWindow,
      volatilityStd: volatilityStd,
      currentMissedPeriods: currentMissedPeriods,
      averageRecoveryPeriods: averageRecoveryPeriods,
      currentPeriodCount: currentPeriodCount
    )
  }
}
