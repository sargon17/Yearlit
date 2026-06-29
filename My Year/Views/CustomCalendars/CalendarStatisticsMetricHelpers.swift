import SharedModels

// swiftlint:disable:next function_parameter_count
func metric(
  id: StatisticMetricID,
  title: String,
  value: String,
  presentation: StatisticMetricPresentation,
  isPremium: Bool,
  explanationTitle: String? = nil,
  meaning: String,
  howToRead: String,
  whyItMatters: String
) -> StatisticMetric {
  StatisticMetric(
    id: id,
    title: title,
    value: value,
    presentation: presentation,
    isPremium: isPremium,
    explanation: MetricExplanation(
      id: id,
      title: explanationTitle ?? title,
      meaning: meaning,
      howToRead: howToRead,
      whyItMatters: whyItMatters
    )
  )
}

func momentumLabel(shortProgress: Double, longProgress: Double) -> String {
  let delta = shortProgress - longProgress
  if delta >= 0.08 { return "Improving" }
  if delta <= -0.08 { return "Slipping" }
  return "Holding"
}

func reliabilityLabel(volatility: Double) -> String {
  if volatility < 0.18 { return "Steady" }
  if volatility < 0.32 { return "Mixed" }
  return "Unstable"
}

func formatAveragePeriods(_ value: Double, cadence: CalendarCadence) -> String {
  let rounded = max(1, Int(value.rounded()))
  let unit: String
  switch cadence {
  case .daily:
    unit = rounded == 1 ? "day" : "days"
  case .weekly:
    unit = rounded == 1 ? "week" : "weeks"
  }
  return "\(rounded) \(unit)"
}

func monthExtremes(from monthlyRates: [Int: Double]) -> (strongest: String?, weakest: String?) {
  let monthsWithSignal = monthlyRates.filter { month, rate in
    (1...12).contains(month) && rate > 0
  }

  guard monthsWithSignal.count >= 2 else {
    return (nil, nil)
  }

  let strongestMonth = monthsWithSignal.max { lhs, rhs in lhs.value < rhs.value }?.key
  let weakestMonth = monthsWithSignal.min { lhs, rhs in lhs.value < rhs.value }?.key

  return (
    strongestMonth.map(monthName),
    weakestMonth.map(monthName)
  )
}
