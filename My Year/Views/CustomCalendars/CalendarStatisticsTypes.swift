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
