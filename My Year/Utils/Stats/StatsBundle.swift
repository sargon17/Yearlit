struct StatsBundle {
    let basic: CalendarStats
    let completionRateTrailingLongWindow: Double
    let bestWeekday: Int?
    let weekdayRates: [Int: Double]
    let monthlyRates: [Int: Double]
    let averageProgressTrailingShortWindow: Double
    let averageProgressTrailingLongWindow: Double
    let volatilityStd: Double
    var currentPeriodCount: Int?
}
