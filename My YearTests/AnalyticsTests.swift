import Foundation
import SharedModels
@testable import My_Year
import Testing

@MainActor
struct AnalyticsTests {
  @Test func trackMergesStandardSnapshotAndEventProperties() {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }

    let analytics = makeAnalytics(defaults: defaults)
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    analytics.track(.moodLogged, properties: ["has_note": .bool(true), "app_version": .string("override")])

    #expect(spy.trackedEvents.count == 1)
    #expect(spy.trackedEvents.first?.event == .moodLogged)
    #expect(spy.trackedEvents.first?.properties["has_note"] == .bool(true))
    #expect(spy.trackedEvents.first?.properties["app_version"] == .string("override"))
    #expect(spy.trackedEvents.first?.properties["mood_tracking_enabled"] != nil)
  }

  @Test func flushQueuedWidgetEventsPreservesQueuedTimestamp() throws {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }
    _ = WidgetAnalyticsQueue.shared.drain()
    defer { _ = WidgetAnalyticsQueue.shared.drain() }

    let analytics = makeAnalytics(defaults: defaults)
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    WidgetAnalyticsQueue.shared.enqueueOpenedApp(properties: [
      "widget_kind": .string("year"),
      "widget_action": .string("open_app"),
      "destination": .string("home")
    ])

    analytics.flushQueuedWidgetEvents()

    #expect(spy.trackedEvents.count == 1)
    #expect(spy.trackedEvents.first?.event == .widgetOpenedApp)
    let timestamp = try #require(spy.trackedEvents.first?.properties["widget_event_timestamp"])
    guard case let .string(value) = timestamp else {
      Issue.record("Expected widget_event_timestamp to be a string")
      return
    }
    #expect(ISO8601DateFormatter().date(from: value) != nil)
  }

  @Test func standardPropertiesUseInjectedDefaults() {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }

    let standardDefaults = UserDefaults.standard
    let originalMoodTracking = standardDefaults.object(forKey: AppStorageKeys.isMoodTrackingEnabled)
    defer { restore(originalMoodTracking, forKey: AppStorageKeys.isMoodTrackingEnabled, in: standardDefaults) }

    standardDefaults.set(false, forKey: AppStorageKeys.isMoodTrackingEnabled)
    defaults.set(true, forKey: AppStorageKeys.isMoodTrackingEnabled)

    let state = makeState(defaults: defaults)

    #expect(state.standardProperties()["mood_tracking_enabled"] == .bool(true))
  }

  @Test func standardSnapshotPropertyKeysAreStableAndDocumented() throws {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }

    let state = makeState(defaults: defaults)
    let actualKeys = Set(state.standardProperties().keys)
    let expectedKeys = Set(AnalyticsCatalog.standardPropertyKeys)

    #expect(actualKeys == expectedKeys)
    #expect(expectedKeys.isDisjoint(with: AnalyticsCatalog.forbiddenSensitivePropertyKeys))

    let document = try String(contentsOfFile: Self.analyticsEventsDocPath, encoding: .utf8)
    for key in AnalyticsCatalog.standardPropertyKeys {
      #expect(document.contains("`\(key)`"))
    }
  }

  @Test func noopAnalyticsClientDoesNotCaptureOrIdentify() {
    let client = NoopAnalyticsClient()

    client.track(.appOpened, properties: ["test": .string("value")])
    client.identify(distinctId: "distinct-id", properties: ["test": .string("value")])
    client.setPersonProperties(["test": .string("value")])
  }

  @Test func firstCheckinCompletionIsOnlyTrackedOnce() {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }

    let analytics = makeAnalytics(defaults: defaults)
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    analytics.markFirstCheckinCompleted()
    analytics.markFirstCheckinCompleted()

    #expect(spy.trackedEvents.map(\.event) == [.firstCheckinCompleted])
    #expect(spy.identifyCalls.isEmpty)
    #expect(spy.personPropertyCalls.count == 2)
    #expect(spy.personPropertyCalls.last?["has_completed_first_checkin"] == .bool(true))
  }

  @Test func eventAndCatalogValuesUseLowercaseSnakeCase() {
    for event in AnalyticsEvent.allCases {
      #expect(isLowercaseSnakeCase(event.rawValue))
    }

    for trigger in PaywallTrigger.allCases {
      #expect(isLowercaseSnakeCase(trigger.rawValue))
    }

    for shareType in ShareType.allCases {
      #expect(isLowercaseSnakeCase(shareType.rawValue))
    }
  }

  @Test func docsListPrivacyBoundariesAndCatalogValues() throws {
    let document = try String(contentsOfFile: Self.analyticsEventsDocPath, encoding: .utf8)

    for event in AnalyticsEvent.allCases {
      #expect(document.contains("`\(event.rawValue)`"))
    }

    for key in AnalyticsCatalog.standardPropertyKeys {
      #expect(document.contains("`\(key)`"))
    }

    for value in PaywallTrigger.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for value in ShareType.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for category in AnalyticsCatalog.forbiddenSensitiveContentCategories {
      #expect(document.localizedCaseInsensitiveContains(category))
    }

    for property in AnalyticsCatalog.forbiddenSensitivePropertyKeys {
      #expect(document.contains("`\(property)`"))
    }
  }

  private func makeAnalytics() -> Analytics {
    let analytics = Analytics(state: makeState())
    return analytics
  }

  private func makeState() -> AnalyticsState {
    makeState(defaults: makeTestDefaults())
  }

  private func makeAnalytics(defaults: UserDefaults) -> Analytics {
    Analytics(state: makeState(defaults: defaults))
  }

  private func makeState(defaults: UserDefaults) -> AnalyticsState {
    AnalyticsState(defaults: defaults)
  }

  private func makeTestDefaults() -> UserDefaults {
    let suiteName = "AnalyticsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  private func cleanupTestDefaults(_ defaults: UserDefaults) {
    for key in defaults.dictionaryRepresentation().keys {
      defaults.removeObject(forKey: key)
    }
  }

  private func restore(_ value: Any?, forKey key: String, in defaults: UserDefaults) {
    if let value {
      defaults.set(value, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
  }

  private func isLowercaseSnakeCase(_ value: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: "^[a-z]+(?:_[a-z]+)*$") else {
      return false
    }

    let range = NSRange(location: 0, length: value.utf16.count)
    return regex.firstMatch(in: value, range: range) != nil
  }

  private static let analyticsEventsDocPath: String = {
    let fileURL = URL(fileURLWithPath: #filePath)
    let repoRoot = fileURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    return repoRoot.appendingPathComponent("docs/analytics-events.md").path
  }()
}

@MainActor
private final class SpyAnalyticsClient: AnalyticsClient {
  private(set) var trackedEvents: [(event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])] = []
  private(set) var identifyCalls: [(distinctId: String, properties: [String: AnalyticsPropertyValue])] = []
  private(set) var personPropertyCalls: [[String: AnalyticsPropertyValue]] = []

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    trackedEvents.append((event: event, properties: properties))
  }

  func identify(distinctId: String, properties: [String: AnalyticsPropertyValue]) {
    identifyCalls.append((distinctId: distinctId, properties: properties))
  }

  func setPersonProperties(_ properties: [String: AnalyticsPropertyValue]) {
    personPropertyCalls.append(properties)
  }
}
