import Foundation

private struct CalendarStatsSnapshot: Codable {
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

private struct StatsBundleSnapshot: Codable {
  let basic: CalendarStatsSnapshot
  let completionRate30d: Double
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let monthlyRates: [Int: Double]
  let rolling7d: Double
  let rolling30d: Double
  let volatilityStd: Double
  let todaysCount: Int?

  init(bundle: StatsBundle) {
    basic = CalendarStatsSnapshot(stats: bundle.basic)
    completionRate30d = bundle.completionRate30d
    bestWeekday = bundle.bestWeekday
    weekdayRates = bundle.weekdayRates
    monthlyRates = bundle.monthlyRates
    rolling7d = bundle.rolling7d
    rolling30d = bundle.rolling30d
    volatilityStd = bundle.volatilityStd
    todaysCount = bundle.todaysCount
  }

  func toBundle() -> StatsBundle {
    StatsBundle(
      basic: basic.toStats(),
      completionRate30d: completionRate30d,
      bestWeekday: bestWeekday,
      weekdayRates: weekdayRates,
      monthlyRates: monthlyRates,
      rolling7d: rolling7d,
      rolling30d: rolling30d,
      volatilityStd: volatilityStd,
      todaysCount: todaysCount
    )
  }
}

private struct OverviewStatsCachePayload: Codable {
  let year: Int
  let daySeedKey: String
  let bundle: StatsBundleSnapshot
}

enum OverviewStatsCache {
  private static let storageKey = "overview.stats.cache.v1"

  static func load(year: Int, daySeedKey: String) -> StatsBundle? {
    guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
    guard let payload = try? JSONDecoder().decode(OverviewStatsCachePayload.self, from: data) else {
      return nil
    }
    guard payload.year == year, payload.daySeedKey == daySeedKey else { return nil }
    return payload.bundle.toBundle()
  }

  static func save(_ bundle: StatsBundle, year: Int, daySeedKey: String) {
    let payload = OverviewStatsCachePayload(
      year: year,
      daySeedKey: daySeedKey,
      bundle: StatsBundleSnapshot(bundle: bundle)
    )
    guard let data = try? JSONEncoder().encode(payload) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
