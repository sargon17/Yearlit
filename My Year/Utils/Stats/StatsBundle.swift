struct StatsBundle {
    let basic: CalendarStats
    let completionRate30d: Double
    let bestWeekday: Int?
    let weekdayRates: [Int: Double]
    let monthlyRates: [Int: Double]
    let rolling7d: Double
    let rolling30d: Double
    let volatilityStd: Double
    var todaysCount: Int?
}
