import Foundation
import SharedModels

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

  func flushQueuedWidgetEvents() {
    let queuedEvents = WidgetAnalyticsQueue.shared.drain()
    guard !queuedEvents.isEmpty else { return }

    for event in queuedEvents {
      guard let analyticsEvent = AnalyticsEvent(rawValue: event.name) else {
        continue
      }

      let properties = Self.convertWidgetProperties(event.properties)
      let merged = state.standardProperties().merging(properties) { _, new in new }
      client.track(analyticsEvent, properties: merged)
    }
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

  private static func convertWidgetProperties(
    _ properties: [String: WidgetAnalyticsPropertyValue]
  ) -> [String: AnalyticsPropertyValue] {
    properties.reduce(into: [:]) { result, entry in
      result[entry.key] = convertWidgetPropertyValue(entry.value)
    }
  }

  private static func convertWidgetPropertyValue(
    _ value: WidgetAnalyticsPropertyValue
  ) -> AnalyticsPropertyValue {
    switch value {
    case let .string(value):
      return .string(value)
    case let .int(value):
      return .int(value)
    case let .double(value):
      return .double(value)
    case let .bool(value):
      return .bool(value)
    }
  }
}
