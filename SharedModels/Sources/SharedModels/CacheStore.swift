import Foundation

public enum CacheScope: String, Codable {
    case overviewDerivedSnapshot
    case overviewGridZByDay
    case overviewGridMappedDays
    case overviewStatsBundle
    case calendarStatsBundle
    case calendarGridMappedDays
    case overviewSlots
}

public struct CacheKey: Hashable, Codable {
    public let scope: CacheScope
    public let identifier: String

    public init(scope: CacheScope, identifier: String) {
        self.scope = scope
        self.identifier = identifier
    }
}

public final class CacheStore {
    public static let shared = CacheStore()

    private let lock = NSLock()
    private var memory: [CacheKey: Any] = [:]
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func get<T>(_ key: CacheKey) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return memory[key] as? T
    }

    public func set<T>(_ key: CacheKey, value: T) {
        lock.lock()
        memory[key] = value
        lock.unlock()
    }

    public func remove(_ key: CacheKey) {
        lock.lock()
        memory.removeValue(forKey: key)
        lock.unlock()
    }

    public func removeMatching(scope: CacheScope, where predicate: @escaping (String) -> Bool) {
        lock.lock()
        defer { lock.unlock() }

        let keysToRemove = memory.keys.filter { $0.scope == scope && predicate($0.identifier) }
        for key in keysToRemove {
            memory.removeValue(forKey: key)
        }
    }

    public func clearMemory() {
        lock.lock()
        memory.removeAll()
        lock.unlock()
    }

    public func loadDisk<T: Codable>(_ key: CacheKey, as _: T.Type = T.self) -> T? {
        guard let data = defaults.data(forKey: diskKey(for: key)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    public func saveDisk<T: Codable>(_ key: CacheKey, value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: diskKey(for: key))
    }

    public func removeDisk(_ key: CacheKey) {
        defaults.removeObject(forKey: diskKey(for: key))
    }

    private func diskKey(for key: CacheKey) -> String {
        "cache.\(key.scope.rawValue).\(key.identifier)"
    }
}
