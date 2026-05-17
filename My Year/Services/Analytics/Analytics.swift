import Foundation

@MainActor
final class Analytics {
  static let shared = Analytics()

  private(set) var client: AnalyticsClient = NoopAnalyticsClient()
  private let state: AnalyticsState
  private var hasConfigured = false

  init(state: AnalyticsState = .shared) {
    self.state = state
  }

  func configure() {
    guard !hasConfigured else { return }
    hasConfigured = true

    let configuration = AppConfig.postHogConfiguration
    guard configuration.isEnabled else {
      client = NoopAnalyticsClient()
      return
    }

    client = PostHogAnalyticsClient(configuration: configuration)
    client.identify(distinctId: state.distinctID, properties: state.standardProperties())
    updatePersonProperties()
  }

  func replaceClient(_ client: AnalyticsClient) {
    self.client = client
  }

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue] = [:]) {
    let merged = state.standardProperties().merging(properties) { _, new in new }
    client.track(event, properties: merged)
  }

  func trackPaywallViewed(trigger: PaywallTrigger) {
    track(
      .paywallViewed,
      properties: [
        "paywall_trigger": .string(trigger.rawValue),
        "paywall_variant": .string("default")
      ]
    )
  }

  func trackShareSheetViewed(type: ShareType) {
    track(
      .shareSheetViewed,
      properties: [
        "share_type": .string(type.rawValue)
      ]
    )
  }

  func updatePersonProperties(_ properties: [String: AnalyticsPropertyValue] = [:]) {
    let merged = state.standardProperties().merging(properties) { _, new in new }
    client.setPersonProperties(merged)
  }

  func markFirstCheckinCompleted() {
    UserDefaults.standard.set(true, forKey: "analytics.has_completed_first_checkin")
    track(.firstCheckinCompleted)
    updatePersonProperties()
  }

  func markFirstPeriodCompleted() {
    UserDefaults.standard.set(true, forKey: "analytics.has_completed_first_period")
    updatePersonProperties()
  }
}
