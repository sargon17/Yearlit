import SharedModels

extension CalendarStatisticsDisplayModel {
  static func shortProgressMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .shortProgress,
      title: context.shortWindowTitle,
      value: statsPercentString(context.averageProgressTrailingShortWindow),
      presentation: .smallTile,
      isPremium: true,
      meaning: "Your progress in the shorter recent window.",
      howToRead: "Higher means you have been closer to your goal recently.",
      whyItMatters: "It reacts quickly when your habit starts improving or slipping."
    )
  }

  static func longProgressMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .longProgress,
      title: context.longWindowTitle,
      value: statsPercentString(context.averageProgressTrailingLongWindow),
      presentation: .smallTile,
      isPremium: true,
      meaning: "Your progress across the longer recent window.",
      howToRead: "Use this as your baseline, not as a score to obsess over.",
      whyItMatters: "It smooths out random good or bad days."
    )
  }

  static func momentumMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .momentum,
      title: "Momentum",
      value: momentumLabel(
        shortProgress: context.averageProgressTrailingShortWindow,
        longProgress: context.averageProgressTrailingLongWindow
      ),
      presentation: .valueRow,
      isPremium: true,
      meaning: "Whether your recent pace is better or worse than your baseline.",
      howToRead:
        "Improving means the short window is ahead of the longer window. "
          + "Slipping means it is behind.",
      whyItMatters: "It tells you what is changing before the long-term numbers catch up."
    )
  }

  static func reliabilityMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .reliability,
      title: "Reliability",
      value: reliabilityLabel(volatility: context.volatilityStdDev),
      presentation: .valueRow,
      isPremium: true,
      meaning: "How steady your habit has been week to week.",
      howToRead:
        "Steady means your weeks look similar. "
          + "Unstable means your good and bad weeks are far apart.",
      whyItMatters: "Reliable habits are easier to protect because they depend less on perfect conditions."
    )
  }
}
