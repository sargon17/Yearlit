import Foundation
import SharedModels
import Testing

struct CacheStoreTests {
    @Test func setIsImmediatelyVisible() {
        let defaults = makeDefaults()
        let store = CacheStore(defaults: defaults)
        let key = CacheKey(scope: .calendarGridMappedDays, identifier: "visible")

        store.set(key, value: [1, 2, 3])

        let cached: [Int]? = store.get(key)
        #expect(cached == [1, 2, 3])
    }

    @Test func removeMatchingRemovesEntriesImmediately() {
        let defaults = makeDefaults()
        let store = CacheStore(defaults: defaults)
        let matchingKey = CacheKey(scope: .overviewSlots, identifier: "calendar-a")
        let otherKey = CacheKey(scope: .overviewSlots, identifier: "calendar-b")

        store.set(matchingKey, value: [ColorToken.active])
        store.set(otherKey, value: [ColorToken.inactive])

        store.removeMatching(scope: .overviewSlots) { $0 == "calendar-a" }

        let removed: [ColorToken]? = store.get(matchingKey)
        let remaining: [ColorToken]? = store.get(otherKey)
        #expect(removed == nil)
        #expect(remaining == [.inactive])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "CacheStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private enum ColorToken: String, Codable {
        case active
        case inactive
    }
}
