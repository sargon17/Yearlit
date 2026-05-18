@testable import My_Year
import Testing

@MainActor
struct OnboardingManagerTests {
  @Test func markAsSeenTracksCompletionOnlyOnce() {
    let analytics = LocalSpyAnalyticsClient()
    let manager = OnboardingManager()
    let previousClient = Analytics.shared.client

    manager.reset()
    defer { manager.reset() }

    Analytics.shared.replaceClient(analytics)
    defer { Analytics.shared.replaceClient(previousClient) }

    manager.markAsSeen()
    manager.markAsSeen()

    #expect(analytics.trackedEvents.map(\.event) == [.onboardingCompleted])
  }
}

@MainActor
private final class LocalSpyAnalyticsClient: AnalyticsClient {
  private(set) var trackedEvents: [(event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])] = []

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    trackedEvents.append((event: event, properties: properties))
  }

  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}

  func setPersonProperties(_: [String: AnalyticsPropertyValue]) {}
}
