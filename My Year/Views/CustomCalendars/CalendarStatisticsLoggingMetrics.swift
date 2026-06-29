import SharedModels

extension CalendarStatisticsDisplayModel {
  static func currentPeriodMetric(_ context: StatisticsDisplayContext, count: Int) -> StatisticMetric {
    metric(
      id: .currentPeriod,
      title: context.currentPeriodTitle,
      value: compactStatsNumber(count),
      presentation: .largeTile,
      isPremium: false,
      meaning: "How much you have logged in the current \(context.periodName).",
      howToRead: "This number resets when a new \(context.periodName) starts.",
      whyItMatters: "It tells you whether you have already shown up for the current \(context.periodName)."
    )
  }

  static func totalMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .total,
      title: "Total",
      value: compactStatsNumber(context.stats.totalCount),
      presentation: .largeTile,
      isPremium: false,
      meaning: "Everything you have logged for this calendar.",
      howToRead:
        "For yes/no habits, this is the number of completed periods. "
          + "For counters, it is the total amount logged.",
      whyItMatters: "It shows the full weight of your effort over time."
    )
  }

  static func bestPeriodMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .bestPeriod,
      title: context.bestPeriodTitle,
      value: compactStatsNumber(context.stats.maxCount),
      presentation: .largeTile,
      isPremium: false,
      meaning: "The highest amount you logged in one \(context.periodName).",
      howToRead: "This is your personal best for a single \(context.periodName).",
      whyItMatters: "It gives you a realistic ceiling based on what you have already done."
    )
  }
}

extension CalendarStatisticsDisplayModel {
  static func currentStreakMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .currentStreak,
      title: "Current",
      value: compactStatsNumber(context.stats.currentStreak),
      presentation: .largeTile,
      isPremium: false,
      explanationTitle: "Current Streak",
      meaning: "How many expected periods in a row you completed.",
      howToRead: "A streak of 5 means you completed the last 5 \(context.periodName)s without a miss.",
      whyItMatters: "It shows your current rhythm, not your entire history."
    )
  }

  static func longestStreakMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .longestStreak,
      title: "Longest",
      value: compactStatsNumber(context.stats.longestStreak),
      presentation: .largeTile,
      isPremium: false,
      explanationTitle: "Longest Streak",
      meaning: "Your longest run without missing.",
      howToRead: "This is the best streak you have ever had for this calendar.",
      whyItMatters: "It shows what you have already proven you can sustain."
    )
  }

  static func activePeriodsMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .activePeriods,
      title: context.activePeriodsTitle,
      value: compactStatsNumber(context.stats.activeDays),
      presentation: .largeTile,
      isPremium: false,
      meaning: "How many \(context.periodName)s have at least one successful log.",
      howToRead: "This counts showed-up \(context.periodName)s, not total logs.",
      whyItMatters: "Showing up repeatedly matters more than one unusually high day."
    )
  }

  static func missedPeriodsMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .missedPeriods,
      title: "Missed",
      value: compactStatsNumber(context.currentMissedPeriods),
      presentation: .largeTile,
      isPremium: false,
      meaning: "How many closed \(context.periodName)s in a row were missed before the current period.",
      howToRead: "If this says 2, the last 2 finished \(context.periodName)s were missed.",
      whyItMatters: "This tells you when the useful move is recovery, not chasing a perfect streak."
    )
  }

  static func recoveryMetric(_ context: StatisticsDisplayContext, periods: Double) -> StatisticMetric {
    metric(
      id: .averageRecovery,
      title: "Recovery",
      value: formatAveragePeriods(periods, cadence: context.cadence),
      presentation: .largeTile,
      isPremium: true,
      meaning: "How long it usually takes you to come back after a miss.",
      howToRead: "Lower is better. A value of 1 day means you usually return right after one missed day.",
      whyItMatters: "Perfect streaks break. Fast recovery is what keeps the habit alive."
    )
  }
}
