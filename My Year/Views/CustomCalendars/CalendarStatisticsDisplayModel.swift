import Foundation
import SharedModels

enum StatisticMetricID: String, Identifiable {
  case currentPeriod
  case total
  case bestPeriod
  case currentStreak
  case longestStreak
  case activePeriods
  case missedPeriods
  case averageRecovery
  case recentConsistency
  case yearPattern
  case strongestMonth
  case weakestMonth
  case bestWeekday
  case weekdayPattern
  case shortProgress
  case longProgress
  case momentum
  case reliability

  var id: String { rawValue }
}

struct MetricExplanation: Identifiable, Equatable {
  let id: StatisticMetricID
  let title: String
  let meaning: String
  let howToRead: String
  let whyItMatters: String
}

enum StatisticMetricPresentation: Equatable {
  case largeTile
  case smallTile
  case valueRow
  case monthlyBars
  case weekdayRibbon
}

struct StatisticMetric: Identifiable, Equatable {
  let id: StatisticMetricID
  let title: String
  let value: String
  let presentation: StatisticMetricPresentation
  let isPremium: Bool
  let explanation: MetricExplanation
}

struct StatisticSection: Identifiable, Equatable {
  let id: String
  let title: String
  let isPremium: Bool
  let metrics: [StatisticMetric]
}

struct CalendarStatisticsDisplayModel: Equatable {
  let sections: [StatisticSection]

  init(
    stats: CalendarStats,
    currentPeriodCount: Int?,
    unit: UnitOfMeasure?,
    currencySymbol: String?,
    completionRateTrailingLongWindow: Double,
    bestWeekday: Int?,
    monthlyRates: [Int: Double],
    averageProgressTrailingShortWindow: Double,
    averageProgressTrailingLongWindow: Double,
    volatilityStdDev: Double,
    currentMissedPeriods: Int,
    averageRecoveryPeriods: Double?,
    isPremium: Bool,
    cadence: CalendarCadence,
    trackingType: TrackingType
  ) {
    let periodName = cadence == .weekly ? "week" : "day"
    let currentPeriodTitle = cadence == .weekly ? "This Week" : "Today"
    let bestPeriodTitle = cadence == .weekly ? "Best Week" : "Best Day"
    let activePeriodsTitle = cadence == .weekly ? "Active Weeks" : "Active Days"
    let shortWindowTitle = cadence == .weekly ? "Last 4 Weeks" : "This Week"
    let longWindowTitle = cadence == .weekly ? "Last 12 Weeks" : "Last 30 Days"
    let entriesLabel = Self.entriesLabel(unit: unit, currencySymbol: currencySymbol)

    var loggingMetrics: [StatisticMetric] = []
    if let currentPeriodCount {
      loggingMetrics.append(
        StatisticMetric(
          id: .currentPeriod,
          title: currentPeriodTitle,
          value: compactStatsNumber(currentPeriodCount),
          presentation: .largeTile,
          isPremium: false,
          explanation: MetricExplanation(
            id: .currentPeriod,
            title: currentPeriodTitle,
            meaning: "How much you have logged in the current \(periodName).",
            howToRead: "This number resets when a new \(periodName) starts.",
            whyItMatters: "It tells you whether you have already shown up for the current \(periodName)."
          )
        )
      )
    }

    loggingMetrics.append(
      StatisticMetric(
        id: .total,
        title: "Total",
        value: compactStatsNumber(stats.totalCount),
        presentation: .largeTile,
        isPremium: false,
        explanation: MetricExplanation(
          id: .total,
          title: "Total",
          meaning: "Everything you have logged for this calendar.",
          howToRead:
            "For yes/no habits, this is the number of completed periods. For counters, it is the total amount logged.",
          whyItMatters: "It shows the full weight of your effort over time."
        )
      )
    )

    if trackingType != .binary {
      loggingMetrics.append(
        StatisticMetric(
          id: .bestPeriod,
          title: bestPeriodTitle,
          value: compactStatsNumber(stats.maxCount),
          presentation: .largeTile,
          isPremium: false,
          explanation: MetricExplanation(
            id: .bestPeriod,
            title: bestPeriodTitle,
            meaning: "The highest amount you logged in one \(periodName).",
            howToRead: "This is your personal best for a single \(periodName).",
            whyItMatters: "It gives you a realistic ceiling based on what you have already done."
          )
        )
      )
    }

    var consistencyMetrics = [
      StatisticMetric(
        id: .currentStreak,
        title: "Current",
        value: compactStatsNumber(stats.currentStreak),
        presentation: .largeTile,
        isPremium: false,
        explanation: MetricExplanation(
          id: .currentStreak,
          title: "Current Streak",
          meaning: "How many expected periods in a row you completed.",
          howToRead: "A streak of 5 means you completed the last 5 \(periodName)s without a miss.",
          whyItMatters: "It shows your current rhythm, not your entire history."
        )
      ),
      StatisticMetric(
        id: .longestStreak,
        title: "Longest",
        value: compactStatsNumber(stats.longestStreak),
        presentation: .largeTile,
        isPremium: false,
        explanation: MetricExplanation(
          id: .longestStreak,
          title: "Longest Streak",
          meaning: "Your longest run without missing.",
          howToRead: "This is the best streak you have ever had for this calendar.",
          whyItMatters: "It shows what you have already proven you can sustain."
        )
      ),
      StatisticMetric(
        id: .activePeriods,
        title: activePeriodsTitle,
        value: compactStatsNumber(stats.activeDays),
        presentation: .largeTile,
        isPremium: false,
        explanation: MetricExplanation(
          id: .activePeriods,
          title: activePeriodsTitle,
          meaning: "How many \(periodName)s have at least one successful log.",
          howToRead: "This counts showed-up \(periodName)s, not total logs.",
          whyItMatters: "Showing up repeatedly matters more than one unusually high day."
        )
      )
    ]

    if currentMissedPeriods > 0 {
      consistencyMetrics.append(
        StatisticMetric(
          id: .missedPeriods,
          title: "Missed",
          value: compactStatsNumber(currentMissedPeriods),
          presentation: .largeTile,
          isPremium: false,
          explanation: MetricExplanation(
            id: .missedPeriods,
            title: "Missed",
            meaning: "How many closed \(periodName)s in a row were missed before the current \(periodName).",
            howToRead: "If this says 2, the last 2 finished \(periodName)s were missed.",
            whyItMatters: "This tells you when the useful move is recovery, not chasing a perfect streak."
          )
        )
      )
    }

    if let averageRecoveryPeriods {
      consistencyMetrics.append(
        StatisticMetric(
          id: .averageRecovery,
          title: "Recovery",
          value: Self.formatAveragePeriods(averageRecoveryPeriods, cadence: cadence),
          presentation: .largeTile,
          isPremium: true,
          explanation: MetricExplanation(
            id: .averageRecovery,
            title: "Recovery",
            meaning: "How long it usually takes you to come back after a miss.",
            howToRead: "Lower is better. A value of 1 day means you usually return right after one missed day.",
            whyItMatters: "Perfect streaks break. Fast recovery is what keeps the habit alive."
          )
        )
      )
    }

    let monthExtremes = Self.monthExtremes(from: monthlyRates)

    var performanceMetrics = [
      StatisticMetric(
        id: .recentConsistency,
        title: "Recent Consistency",
        value: statsPercentString(completionRateTrailingLongWindow),
        presentation: .valueRow,
        isPremium: true,
        explanation: MetricExplanation(
          id: .recentConsistency,
          title: "Recent Consistency",
          meaning: cadence == .weekly
            ? "How often you completed the habit across the last 12 weeks."
            : "How often you completed the habit across the last 30 days.",
          howToRead: "80% means you completed about 8 out of every 10 expected periods.",
          whyItMatters: "Consistency is the clearest signal that the habit is becoming stable."
        )
      ),
      StatisticMetric(
        id: .yearPattern,
        title: "Year Pattern",
        value: "",
        presentation: .monthlyBars,
        isPremium: true,
        explanation: MetricExplanation(
          id: .yearPattern,
          title: "Year Pattern",
          meaning: "How your progress changes month by month.",
          howToRead: "Stronger months are shown with stronger color.",
          whyItMatters: "It helps you spot seasons where the habit is easier or harder to maintain."
        )
      )
    ]

    if let strongest = monthExtremes.strongest {
      performanceMetrics.append(
        StatisticMetric(
          id: .strongestMonth,
          title: "Strongest Month",
          value: strongest,
          presentation: .valueRow,
          isPremium: true,
          explanation: MetricExplanation(
            id: .strongestMonth,
            title: "Strongest Month",
            meaning: "The month where this habit has been strongest this year.",
            howToRead: "Use it as a clue. Something about that month made the habit easier.",
            whyItMatters: "Strong months can show which routines or seasons help you succeed."
          )
        )
      )
    }

    if let weakest = monthExtremes.weakest {
      performanceMetrics.append(
        StatisticMetric(
          id: .weakestMonth,
          title: "Weakest Month",
          value: weakest,
          presentation: .valueRow,
          isPremium: true,
          explanation: MetricExplanation(
            id: .weakestMonth,
            title: "Weakest Month",
            meaning: "The month where this habit has been hardest this year.",
            howToRead: "It is not a failure label. It points to where the habit needs more support.",
            whyItMatters: "Weak months help you plan around predictable friction."
          )
        )
      )
    }

    var patternMetrics: [StatisticMetric] = []
    if cadence == .daily {
      patternMetrics = [
        StatisticMetric(
          id: .bestWeekday,
          title: "Best Day to Show Up",
          value: bestWeekday.map { weekdayName($0) } ?? "-",
          presentation: .valueRow,
          isPremium: true,
          explanation: MetricExplanation(
            id: .bestWeekday,
            title: "Best Day to Show Up",
            meaning: "The weekday where you usually make the most progress.",
            howToRead: "If it says Monday, Mondays have been your strongest day so far.",
            whyItMatters: "Use strong days as anchors and plan weaker days more carefully."
          )
        ),
        StatisticMetric(
          id: .weekdayPattern,
          title: "Week Pattern",
          value: "",
          presentation: .weekdayRibbon,
          isPremium: true,
          explanation: MetricExplanation(
            id: .weekdayPattern,
            title: "Week Pattern",
            meaning: "How each weekday usually performs.",
            howToRead: "Stronger color means that weekday has been stronger for this habit.",
            whyItMatters: "It shows whether the habit depends on your weekly routine."
          )
        )
      ]
    }

    let momentumValue = Self.momentumLabel(
      shortProgress: averageProgressTrailingShortWindow,
      longProgress: averageProgressTrailingLongWindow
    )
    let reliabilityValue = Self.reliabilityLabel(volatility: volatilityStdDev)
    let trendMetrics = [
      StatisticMetric(
        id: .shortProgress,
        title: shortWindowTitle,
        value: statsPercentString(averageProgressTrailingShortWindow),
        presentation: .smallTile,
        isPremium: true,
        explanation: MetricExplanation(
          id: .shortProgress,
          title: shortWindowTitle,
          meaning: "Your progress in the shorter recent window.",
          howToRead: "Higher means you have been closer to your goal recently.",
          whyItMatters: "It reacts quickly when your habit starts improving or slipping."
        )
      ),
      StatisticMetric(
        id: .longProgress,
        title: longWindowTitle,
        value: statsPercentString(averageProgressTrailingLongWindow),
        presentation: .smallTile,
        isPremium: true,
        explanation: MetricExplanation(
          id: .longProgress,
          title: longWindowTitle,
          meaning: "Your progress across the longer recent window.",
          howToRead: "Use this as your baseline, not as a score to obsess over.",
          whyItMatters: "It smooths out random good or bad days."
        )
      ),
      StatisticMetric(
        id: .momentum,
        title: "Momentum",
        value: momentumValue,
        presentation: .valueRow,
        isPremium: true,
        explanation: MetricExplanation(
          id: .momentum,
          title: "Momentum",
          meaning: "Whether your recent pace is better or worse than your baseline.",
          howToRead: "Improving means the short window is ahead of the longer window. Slipping means it is behind.",
          whyItMatters: "It tells you what is changing before the long-term numbers catch up."
        )
      ),
      StatisticMetric(
        id: .reliability,
        title: "Reliability",
        value: reliabilityValue,
        presentation: .valueRow,
        isPremium: true,
        explanation: MetricExplanation(
          id: .reliability,
          title: "Reliability",
          meaning: "How steady your habit has been week to week.",
          howToRead: "Steady means your weeks look similar. Unstable means your good and bad weeks are far apart.",
          whyItMatters: "Reliable habits are easier to protect because they depend less on perfect conditions."
        )
      )
    ]

    var sections = [
      StatisticSection(id: "logging", title: entriesLabel, isPremium: false, metrics: loggingMetrics),
      StatisticSection(id: "consistency", title: "Consistency", isPremium: false, metrics: consistencyMetrics),
      StatisticSection(id: "performance", title: "Performance", isPremium: !isPremium, metrics: performanceMetrics)
    ]

    if !patternMetrics.isEmpty {
      sections.append(
        StatisticSection(id: "patterns", title: "Patterns", isPremium: !isPremium, metrics: patternMetrics))
    }

    sections.append(StatisticSection(id: "momentum", title: "Momentum", isPremium: !isPremium, metrics: trendMetrics))
    self.sections = sections
  }

  private static func entriesLabel(unit: UnitOfMeasure?, currencySymbol: String?) -> String {
    guard let unit else { return "Times" }
    return unit == .currency ? (currencySymbol ?? "€") : unit.displayName
  }

  private static func momentumLabel(shortProgress: Double, longProgress: Double) -> String {
    let delta = shortProgress - longProgress
    if delta >= 0.08 { return "Improving" }
    if delta <= -0.08 { return "Slipping" }
    return "Holding"
  }

  private static func reliabilityLabel(volatility: Double) -> String {
    if volatility < 0.18 { return "Steady" }
    if volatility < 0.32 { return "Mixed" }
    return "Unstable"
  }

  private static func formatAveragePeriods(_ value: Double, cadence: CalendarCadence) -> String {
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

  private static func monthExtremes(from monthlyRates: [Int: Double]) -> (strongest: String?, weakest: String?) {
    let monthsWithSignal =
      monthlyRates
      .filter { month, rate in (1...12).contains(month) && rate > 0 }

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
}

func statsPercentString(_ value: Double) -> String {
  let percentage = max(0, min(1, value))
  return String(format: "%.0f%%", percentage * 100)
}

func weekdayName(_ idx: Int) -> String {
  let symbols = Calendar.current.shortWeekdaySymbols
  let clamped = max(1, min(7, idx))
  return symbols[clamped - 1]
}

func monthName(_ idx: Int) -> String {
  let symbols = Calendar.current.shortMonthSymbols
  let clamped = max(1, min(12, idx))
  return symbols[clamped - 1]
}
