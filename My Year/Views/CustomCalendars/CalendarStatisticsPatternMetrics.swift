import SharedModels

extension CalendarStatisticsDisplayModel {
  static func recentConsistencyMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .recentConsistency,
      title: "Recent Consistency",
      value: statsPercentString(context.completionRateTrailingLongWindow),
      presentation: .valueRow,
      isPremium: true,
      meaning: context.cadence == .weekly
        ? "How often you completed the habit across the last 12 weeks."
        : "How often you completed the habit across the last 30 days.",
      howToRead: "80% means you completed about 8 out of every 10 expected periods.",
      whyItMatters: "Consistency is the clearest signal that the habit is becoming stable."
    )
  }

  static func yearPatternMetric() -> StatisticMetric {
    metric(
      id: .yearPattern,
      title: "Year Pattern",
      value: "",
      presentation: .monthlyBars,
      isPremium: true,
      meaning: "How your progress changes month by month.",
      howToRead: "Stronger months are shown with stronger color.",
      whyItMatters: "It helps you spot seasons where the habit is easier or harder to maintain."
    )
  }

  static func strongestMonthMetric(_ month: String) -> StatisticMetric {
    metric(
      id: .strongestMonth,
      title: "Strongest Month",
      value: month,
      presentation: .valueRow,
      isPremium: true,
      meaning: "The month where this habit has been strongest this year.",
      howToRead: "Use it as a clue. Something about that month made the habit easier.",
      whyItMatters: "Strong months can show which routines or seasons help you succeed."
    )
  }

  static func weakestMonthMetric(_ month: String) -> StatisticMetric {
    metric(
      id: .weakestMonth,
      title: "Weakest Month",
      value: month,
      presentation: .valueRow,
      isPremium: true,
      meaning: "The month where this habit has been hardest this year.",
      howToRead: "It is not a failure label. It points to where the habit needs more support.",
      whyItMatters: "Weak months help you plan around predictable friction."
    )
  }

  static func bestWeekdayMetric(_ context: StatisticsDisplayContext) -> StatisticMetric {
    metric(
      id: .bestWeekday,
      title: "Best Day to Show Up",
      value: context.bestWeekday.map { weekdayName($0) } ?? "-",
      presentation: .valueRow,
      isPremium: true,
      meaning: "The weekday where you usually make the most progress.",
      howToRead: "If it says Monday, Mondays have been your strongest day so far.",
      whyItMatters: "Use strong days as anchors and plan weaker days more carefully."
    )
  }

  static func weekdayPatternMetric() -> StatisticMetric {
    metric(
      id: .weekdayPattern,
      title: "Week Pattern",
      value: "",
      presentation: .weekdayRibbon,
      isPremium: true,
      meaning: "How each weekday usually performs.",
      howToRead: "Stronger color means that weekday has been stronger for this habit.",
      whyItMatters: "It shows whether the habit depends on your weekly routine."
    )
  }
}
