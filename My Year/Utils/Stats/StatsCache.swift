import Foundation

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

final class StatsCache {
  private var cache: [String: StatsBundle] = [:]
  private let queue = DispatchQueue(label: "StatsCache", attributes: .concurrent)

  func get(_ key: String) -> StatsBundle? {
    queue.sync { cache[key] }
  }

  func set(_ key: String, value: StatsBundle) {
    queue.async(flags: .barrier) { self.cache[key] = value }
  }

  func clear() {
    queue.async(flags: .barrier) { self.cache.removeAll() }
  }
}
