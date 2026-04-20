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
        currentPeriodCount = bundle.currentPeriodCount
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
            currentPeriodCount: currentPeriodCount
        )
    }
}
