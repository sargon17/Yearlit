import SharedModels

struct StatisticsDisplayContext {
  let stats: CalendarStats
  let currentPeriodCount: Int?
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  let completionRateTrailingLongWindow: Double
  let bestWeekday: Int?
  let monthlyRates: [Int: Double]
  let averageProgressTrailingShortWindow: Double
  let averageProgressTrailingLongWindow: Double
  let volatilityStdDev: Double
  let currentMissedPeriods: Int
  let averageRecoveryPeriods: Double?
  let isPremium: Bool
  let cadence: CalendarCadence
  let trackingType: TrackingType

  var periodName: String { cadence == .weekly ? "week" : "day" }
  var currentPeriodTitle: String { cadence == .weekly ? "This Week" : "Today" }
  var bestPeriodTitle: String { cadence == .weekly ? "Best Week" : "Best Day" }
  var activePeriodsTitle: String { cadence == .weekly ? "Active Weeks" : "Active Days" }
  var shortWindowTitle: String { cadence == .weekly ? "Last 4 Weeks" : "This Week" }
  var longWindowTitle: String { cadence == .weekly ? "Last 12 Weeks" : "Last 30 Days" }

  var entriesLabel: String {
    guard let unit else { return "Times" }
    return unit == .currency ? (currencySymbol ?? "€") : unit.displayName
  }
}
