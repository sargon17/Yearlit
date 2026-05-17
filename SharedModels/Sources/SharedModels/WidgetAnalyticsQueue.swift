import Foundation

public enum WidgetAnalyticsKind: String, Codable, CaseIterable {
    case year
    case habits
    case streak
}

public enum WidgetAnalyticsFamily: String, Codable, CaseIterable {
    case systemSmall
    case systemMedium
    case systemLarge
    case other
}

public struct WidgetAnalyticsPayload: Codable, Equatable {
    public let eventName: String
    public let timestamp: Date
    public let properties: [String: WidgetAnalyticsPropertyValue]

    public init(
        eventName: String,
        timestamp: Date = Date(),
        properties: [String: WidgetAnalyticsPropertyValue] = [:]
    ) {
        self.eventName = eventName
        self.timestamp = timestamp
        self.properties = properties
    }
}

public enum WidgetAnalyticsPropertyValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    private enum CodingKeys: String, CodingKey {
        case kind
        case string
        case int
        case double
        case bool
    }

    private enum Kind: String, Codable {
        case string
        case int
        case double
        case bool
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .string:
            self = .string(try container.decode(String.self, forKey: .string))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .int))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .double))
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .bool))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(value):
            try container.encode(Kind.string, forKey: .kind)
            try container.encode(value, forKey: .string)
        case let .int(value):
            try container.encode(Kind.int, forKey: .kind)
            try container.encode(value, forKey: .int)
        case let .double(value):
            try container.encode(Kind.double, forKey: .kind)
            try container.encode(value, forKey: .double)
        case let .bool(value):
            try container.encode(Kind.bool, forKey: .kind)
            try container.encode(value, forKey: .bool)
        }
    }
}

public struct WidgetAnalyticsEvent: Codable, Equatable {
    public let name: String
    public let timestamp: Date
    public let properties: [String: WidgetAnalyticsPropertyValue]

    public init(name: String, timestamp: Date = Date(), properties: [String: WidgetAnalyticsPropertyValue] = [:]) {
        self.name = name
        self.timestamp = timestamp
        self.properties = properties
    }
}

public final class WidgetAnalyticsQueue {
    public static let shared = WidgetAnalyticsQueue()

    private let defaults: UserDefaults?
    private let storageKey = "widget.analytics.queue.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let retention: TimeInterval = 60 * 60 * 24 * 7

    public init(defaults: UserDefaults? = UserDefaults(suiteName: "group.sargon17.My-Year")) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func enqueueTimelineLoaded(properties: [String: WidgetAnalyticsPropertyValue]) {
        enqueue(.init(name: "widget_timeline_loaded", properties: properties))
    }

    public func enqueueOpenedApp(properties: [String: WidgetAnalyticsPropertyValue]) {
        enqueue(.init(name: "widget_opened_app", properties: properties))
    }

    public func enqueueQuickAddPerformed(properties: [String: WidgetAnalyticsPropertyValue]) {
        enqueue(.init(name: "widget_quick_add_performed", properties: properties))
    }

    public func enqueueQuickAddOpened(properties: [String: WidgetAnalyticsPropertyValue]) {
        enqueue(.init(name: "widget_quick_add_opened", properties: properties))
    }

    public func drain() -> [WidgetAnalyticsEvent] {
        guard let defaults else { return [] }

        let events = load().filter { Date().timeIntervalSince($0.timestamp) <= retention }
        defaults.removeObject(forKey: storageKey)
        return events
    }

    private func enqueue(_ event: WidgetAnalyticsEvent) {
        guard let defaults else { return }

        var events = load().filter { Date().timeIntervalSince($0.timestamp) <= retention }
        if Self.shouldDedupe(event) {
            let dedupeKey = Self.deduplicationKey(for: event)
            events.removeAll { Self.deduplicationKey(for: $0) == dedupeKey }
        }
        events.append(event)
        defaults.set(encode(events), forKey: storageKey)
    }

    private func load() -> [WidgetAnalyticsEvent] {
        guard let defaults else { return [] }
        guard let data = defaults.data(forKey: storageKey),
            let events = try? decoder.decode([WidgetAnalyticsEvent].self, from: data)
        else {
            return []
        }
        return events
    }

    private func encode(_ events: [WidgetAnalyticsEvent]) -> Data {
        (try? encoder.encode(events)) ?? Data()
    }

    private static func shouldDedupe(_ event: WidgetAnalyticsEvent) -> Bool {
        event.name == "widget_timeline_loaded"
    }

    private static func deduplicationKey(for event: WidgetAnalyticsEvent) -> String {
        let day = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: event.timestamp))
        let properties = event.properties
            .map { "\($0.key)=\($0.value.hashableDescription)" }
            .sorted()
            .joined(separator: "|")
        return "\(day)|\(event.name)|\(properties)"
    }
}

private extension WidgetAnalyticsPropertyValue {
    var hashableDescription: String {
        switch self {
        case let .string(value): return "s:\(value)"
        case let .int(value): return "i:\(value)"
        case let .double(value): return "d:\(value)"
        case let .bool(value): return "b:\(value)"
        }
    }
}
