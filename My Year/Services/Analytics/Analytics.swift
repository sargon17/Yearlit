import Foundation
import SharedModels

@MainActor
protocol OnboardingAnalyticsTracking {
  func trackOnboardingStepViewed(stepId: String)
  func trackOnboardingAction(_ action: OnboardingAction)
  func markActivationCompleted(source: ActivationSource)
}

@MainActor
final class Analytics {
  static let shared = Analytics()

  private(set) var client: AnalyticsClient = NoopAnalyticsClient()
  private let state: AnalyticsState
  private var hasConfigured = false

  init(state: AnalyticsState? = nil) {
    self.state = state ?? .shared
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
    client.track(event, properties: Self.sanitizedProperties(merged))
  }

  func trackShareSheetViewed(type: ShareType) {
    track(
      .shareSheetViewed,
      properties: [
        "share_type": .string(type.rawValue)
      ]
    )
  }

  func trackOnboardingStepViewed(stepId: String) {
    track(
      .onboardingStepViewed,
      properties: [
        "step_id": .string(stepId)
      ]
    )
  }

  func trackOnboardingAction(_ action: OnboardingAction) {
    track(
      .onboardingActionPerformed,
      properties: [
        "action": .string(action.rawValue)
      ]
    )
  }

  func markActivationCompleted(source: ActivationSource) {
    guard !state.hasCompletedActivation else { return }

    state.markActivationCompleted()
    track(
      .activationCompleted,
      properties: [
        "activation_source": .string(source.rawValue)
      ]
    )
    updatePersonProperties()
  }

  func flushQueuedWidgetEvents() {
    let queuedEvents = WidgetAnalyticsQueue.shared.drain()
    guard !queuedEvents.isEmpty else { return }

    for event in queuedEvents {
      guard let analyticsEvent = AnalyticsEvent(rawValue: event.name) else {
        continue
      }

      var properties = Self.convertWidgetProperties(event.properties)
      properties["widget_event_timestamp"] = .string(
        Self.widgetEventTimestampFormatter.string(from: event.timestamp))
      let merged = state.standardProperties().merging(properties) { _, new in new }
      client.track(analyticsEvent, properties: Self.sanitizedProperties(merged))
    }
  }

  func updatePersonProperties(_ properties: [String: AnalyticsPropertyValue] = [:]) {
    let merged = state.standardProperties().merging(properties) { _, new in new }
    client.setPersonProperties(Self.sanitizedProperties(merged))
  }

  func markFirstCheckinCompleted() {
    guard !state.hasCompletedFirstCheckin else { return }

    state.markFirstCheckinCompleted()
    track(.firstCheckinCompleted)
    markActivationCompleted(source: .calendarCheckin)
    updatePersonProperties()
  }

  func markFirstPeriodCompleted() {
    guard !state.hasCompletedFirstPeriod else { return }

    state.markFirstPeriodCompleted()
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
    case .string(let value):
      return .string(value)
    case .int(let value):
      return .int(value)
    case .double(let value):
      return .double(value)
    case .bool(let value):
      return .bool(value)
    }
  }

  private static let widgetEventTimestampFormatter = ISO8601DateFormatter()

  private static func sanitizedProperties(
    _ properties: [String: AnalyticsPropertyValue]
  ) -> [String: AnalyticsPropertyValue] {
    let forbiddenKeys = Set(AnalyticsCatalog.forbiddenSensitivePropertyKeys)
    let sensitiveKeys = Set(properties.keys).intersection(forbiddenKeys)

    if !sensitiveKeys.isEmpty {
      let keys = sensitiveKeys.sorted().joined(separator: ", ")
      assertionFailure("Analytics properties include forbidden sensitive keys: \(keys)")
      return properties.filter { !forbiddenKeys.contains($0.key) }
    }

    return properties
  }
}

extension Analytics: OnboardingAnalyticsTracking {}
