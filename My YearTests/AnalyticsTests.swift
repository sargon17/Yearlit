import Foundation
import SharedModels
import Testing

@testable import My_Year

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
    guard case .string(let value) = timestamp else {
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
    defer {
      restore(originalMoodTracking, forKey: AppStorageKeys.isMoodTrackingEnabled, in: standardDefaults)
    }

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

    #expect(spy.trackedEvents.map(\.event) == [.firstCheckinCompleted, .activationCompleted])
    #expect(spy.identifyCalls.isEmpty)
    #expect(spy.personPropertyCalls.count == 3)
    #expect(spy.personPropertyCalls.last?["has_completed_first_checkin"] == .bool(true))
    #expect(spy.personPropertyCalls.last?["has_completed_activation"] == .bool(true))
  }

  @Test func paywallViewedUsesProvidedVariant() {
    let analytics = makeAnalytics()
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)

    analytics.trackPaywallViewed(trigger: .onboarding, variant: .commitmentProtectionV1)

    #expect(spy.trackedEvents.first?.event == .paywallViewed)
    #expect(spy.trackedEvents.first?.properties["paywall_trigger"] == .string("onboarding"))
    #expect(spy.trackedEvents.first?.properties["paywall_variant"] == .string("commitment_protection_v1"))
  }

  @Test func paywallPurchaseEventsUseCoarseSafePackageProperties() {
    let analytics = makeAnalytics()
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)
    let package = PaywallPackageAnalyticsContext(
      identifier: "$rc_annual",
      type: .annual,
      hasFreeTrial: true,
      localizedPrice: "$19.99"
    )

    analytics.trackPaywallPurchaseStarted(
      trigger: .onboarding,
      variant: .commitmentProtectionV1,
      package: package
    )
    analytics.trackPaywallPurchaseFailed(
      trigger: .onboarding,
      variant: .commitmentProtectionV1,
      package: package,
      errorCategory: .purchaseFailed
    )

    #expect(spy.trackedEvents.map(\.event) == [.paywallPurchaseStarted, .paywallPurchaseFailed])
    #expect(spy.trackedEvents.first?.properties["package_identifier"] == .string("$rc_annual"))
    #expect(spy.trackedEvents.first?.properties["package_type"] == .string("annual"))
    #expect(spy.trackedEvents.first?.properties["has_free_trial"] == .bool(true))
    #expect(spy.trackedEvents.first?.properties["localized_price"] == .string("$19.99"))
    #expect(spy.trackedEvents.last?.properties["error_category"] == .string("purchase_failed"))
  }

  @Test func eventAndCatalogValuesUseLowercaseSnakeCase() {
    for event in AnalyticsEvent.allCases {
      #expect(isLowercaseSnakeCase(event.rawValue))
    }

    for trigger in PaywallTrigger.allCases {
      #expect(isLowercaseSnakeCase(trigger.rawValue))
    }

    for variant in PaywallVariant.allCases {
      #expect(isLowercaseSnakeCase(variant.rawValue))
    }

    for packageType in PaywallPackageType.allCases {
      #expect(isLowercaseSnakeCase(packageType.rawValue))
    }

    for errorCategory in PaywallErrorCategory.allCases {
      #expect(isLowercaseSnakeCase(errorCategory.rawValue))
    }

    for shareType in ShareType.allCases {
      #expect(isLowercaseSnakeCase(shareType.rawValue))
    }

    for activationSource in ActivationSource.allCases {
      #expect(isLowercaseSnakeCase(activationSource.rawValue))
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

    for value in PaywallVariant.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for value in PaywallPackageType.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for value in PaywallErrorCategory.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for value in ShareType.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for value in ActivationSource.allCases.map(\.rawValue) {
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
    let repoRoot =
      fileURL
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
