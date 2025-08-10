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

class StatsCache {
  var cache: [String: StatsBundle] = [:]
  let queue = DispatchQueue(label: "StatsCache", attributes: .concurrent)

  func get(_ key: String) -> StatsBundle? {
    queue.sync { cache[key] }
  }

  func set(_ key: String, value: StatsBundle) {
    queue.sync(flags: .barrier) { cache[key] = value }
  }

  func clear() {
    queue.sync(flags: .barrier) { cache.removeAll() }
  }
}
