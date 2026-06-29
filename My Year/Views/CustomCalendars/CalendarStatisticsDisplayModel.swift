import SharedModels

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
    let context = StatisticsDisplayContext(
      stats: stats,
      currentPeriodCount: currentPeriodCount,
      unit: unit,
      currencySymbol: currencySymbol,
      completionRateTrailingLongWindow: completionRateTrailingLongWindow,
      bestWeekday: bestWeekday,
      monthlyRates: monthlyRates,
      averageProgressTrailingShortWindow: averageProgressTrailingShortWindow,
      averageProgressTrailingLongWindow: averageProgressTrailingLongWindow,
      volatilityStdDev: volatilityStdDev,
      currentMissedPeriods: currentMissedPeriods,
      averageRecoveryPeriods: averageRecoveryPeriods,
      isPremium: isPremium,
      cadence: cadence,
      trackingType: trackingType
    )
    sections = Self.makeSections(context)
  }
}

private extension CalendarStatisticsDisplayModel {
  static func makeSections(_ context: StatisticsDisplayContext) -> [StatisticSection] {
    var sections = [
      StatisticSection(
        id: "logging",
        title: context.entriesLabel,
        isPremium: false,
        metrics: loggingMetrics(context)
      ),
      StatisticSection(
        id: "consistency",
        title: "Consistency",
        isPremium: false,
        metrics: consistencyMetrics(context)
      ),
      StatisticSection(
        id: "performance",
        title: "Performance",
        isPremium: !context.isPremium,
        metrics: performanceMetrics(context)
      )
    ]

    let patterns = patternMetrics(context)
    if !patterns.isEmpty {
      sections.append(
        StatisticSection(id: "patterns", title: "Patterns", isPremium: !context.isPremium, metrics: patterns)
      )
    }

    sections.append(
      StatisticSection(
        id: "momentum",
        title: "Momentum",
        isPremium: !context.isPremium,
        metrics: trendMetrics(context)
      )
    )
    return sections
  }

  static func loggingMetrics(_ context: StatisticsDisplayContext) -> [StatisticMetric] {
    var metrics: [StatisticMetric] = []
    if let currentPeriodCount = context.currentPeriodCount {
      metrics.append(currentPeriodMetric(context, count: currentPeriodCount))
    }
    metrics.append(totalMetric(context))

    if context.trackingType != .binary {
      metrics.append(bestPeriodMetric(context))
    }
    return metrics
  }

  static func consistencyMetrics(_ context: StatisticsDisplayContext) -> [StatisticMetric] {
    var metrics = [
      currentStreakMetric(context),
      longestStreakMetric(context),
      activePeriodsMetric(context)
    ]

    if context.currentMissedPeriods > 0 {
      metrics.append(missedPeriodsMetric(context))
    }

    if let averageRecoveryPeriods = context.averageRecoveryPeriods {
      metrics.append(recoveryMetric(context, periods: averageRecoveryPeriods))
    }
    return metrics
  }

  static func performanceMetrics(_ context: StatisticsDisplayContext) -> [StatisticMetric] {
    let monthExtremes = monthExtremes(from: context.monthlyRates)
    var metrics = [recentConsistencyMetric(context), yearPatternMetric()]

    if let strongest = monthExtremes.strongest {
      metrics.append(strongestMonthMetric(strongest))
    }
    if let weakest = monthExtremes.weakest {
      metrics.append(weakestMonthMetric(weakest))
    }
    return metrics
  }

  static func patternMetrics(_ context: StatisticsDisplayContext) -> [StatisticMetric] {
    guard context.cadence == .daily else { return [] }
    return [
      bestWeekdayMetric(context),
      weekdayPatternMetric()
    ]
  }

  static func trendMetrics(_ context: StatisticsDisplayContext) -> [StatisticMetric] {
    [
      shortProgressMetric(context),
      longProgressMetric(context),
      momentumMetric(context),
      reliabilityMetric(context)
    ]
  }
}
