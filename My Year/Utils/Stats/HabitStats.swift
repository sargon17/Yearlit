import Foundation
import SharedModels

public enum StatsPeriod: Equatable {
  case lastNDays(Int)
  case thisMonth(Int)  // year
  case thisYear(Int)  // year
}

public struct BasicHabitStats {
  public let activeDays: Int
  public let totalCount: Int
  public let maxCount: Int
  public let longestStreak: Int
  public let currentStreak: Int
}

public struct HabitRatesSnapshot {
  public let completionRate: Double  // 0...1
  public let attainmentRate: Double?  // target type only, 0...1
  public let nearMissRate: Double?  // target type only, 0...1
  public let overAchievementRate: Double?  // target type only, 0...1
}

public struct WeekdayBreakdown {
  public let ratesByWeekday: [Int: Double]  // 1...7 (Calendar.current)
  public let bestWeekday: Int?  // 1...7
}

public struct RollingConsistencySnapshot {
  public let average7d: Double  // 0...1
  public let average30d: Double  // 0...1
}

public struct VolatilitySnapshot {
  public let weeklyCompletionRateStdDev: Double
}
