import Foundation

private struct OverviewGridCachePayload: Codable {
  let year: Int
  let daySeedKey: String
  let zByDay: [String: Double]
}

enum OverviewGridCache {
  private static let storageKey = "overview.grid.cache.v1"

  static func load(year: Int, daySeedKey: String) -> [String: Double]? {
    guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
    guard let payload = try? JSONDecoder().decode(OverviewGridCachePayload.self, from: data) else {
      return nil
    }
    guard payload.year == year, payload.daySeedKey == daySeedKey else { return nil }
    return payload.zByDay
  }

  static func save(zByDay: [String: Double], year: Int, daySeedKey: String) {
    let payload = OverviewGridCachePayload(year: year, daySeedKey: daySeedKey, zByDay: zByDay)
    guard let data = try? JSONEncoder().encode(payload) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
