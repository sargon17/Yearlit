import Foundation
@testable import My_Year
import Testing

@MainActor
struct AnalyticsTests {
  @Test func trackMergesStandardSnapshotAndEventProperties() {
    resetAnalyticsDefaults()
    defer { resetAnalyticsDefaults() }

    let analytics = makeAnalytics()
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    analytics.track(.moodLogged, properties: ["has_note": .bool(true), "app_version": .string("override")])

    #expect(spy.trackedEvents.count == 1)
    #expect(spy.trackedEvents.first?.event == .moodLogged)
    #expect(spy.trackedEvents.first?.properties["has_note"] == .bool(true))
    #expect(spy.trackedEvents.first?.properties["app_version"] == .string("override"))
    #expect(spy.trackedEvents.first?.properties["mood_tracking_enabled"] != nil)
  }

  @Test func standardSnapshotPropertyKeysAreStableAndDocumented() throws {
    resetAnalyticsDefaults()
    defer { resetAnalyticsDefaults() }

    let state = makeState()
    let actualKeys = Set(state.standardProperties().keys)
    let expectedKeys = Set(AnalyticsCatalog.standardPropertyKeys)

    #expect(actualKeys == expectedKeys)

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
    resetAnalyticsDefaults()
    defer { resetAnalyticsDefaults() }

    let analytics = makeAnalytics()
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    analytics.markFirstCheckinCompleted()
    analytics.markFirstCheckinCompleted()

    #expect(spy.trackedEvents.map(\.event) == [.firstCheckinCompleted])
    #expect(spy.identifyCalls == [])
    #expect(spy.personPropertyCalls == 2)
    #expect(spy.personPropertyCalls.last?.properties["has_completed_first_checkin"] == .bool(true))
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
    AnalyticsState(defaults: UserDefaults.standard)
  }

  private func resetAnalyticsDefaults() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "analytics.has_completed_first_checkin")
    defaults.removeObject(forKey: "analytics.has_completed_first_period")
    defaults.removeObject(forKey: "analytics.distinct_id")
    defaults.removeObject(forKey: "analytics.install_date")
  }

  private func isLowercaseSnakeCase(_ value: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: "^[a-z]+(?:_[a-z]+)*$") else {
      return false
    }

    let range = NSRange(location: 0, length: value.utf16.count)
    return regex.firstMatch(in: value, range: range) != nil
  }

  private static let analyticsEventsDocPath = "/home/agent/workspace/docs/analytics-events.md"
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
