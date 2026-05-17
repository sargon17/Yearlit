import Foundation
@testable import My_Year
import Testing

@MainActor
struct AnalyticsTests {
  @Test func trackMergesStandardSnapshotAndEventProperties() {
    let analytics = Analytics.shared
    let originalClient = analytics.client
    let spy = SpyAnalyticsClient()
    analytics.replaceClient(spy)
    defer { analytics.replaceClient(originalClient) }

    analytics.track(.moodLogged, properties: ["has_note": .bool(true)])

    #expect(spy.trackedEvents.count == 1)
    #expect(spy.trackedEvents.first?.event == .moodLogged)
    #expect(spy.trackedEvents.first?.properties["has_note"] == .bool(true))
    #expect(spy.trackedEvents.first?.properties["app_version"] != nil)
    #expect(spy.trackedEvents.first?.properties["mood_tracking_enabled"] != nil)
  }
}

@MainActor
private final class SpyAnalyticsClient: AnalyticsClient {
  private(set) var trackedEvents: [(event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])] = []

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    trackedEvents.append((event: event, properties: properties))
  }

  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}

  func setPersonProperties(_: [String: AnalyticsPropertyValue]) {}
}
