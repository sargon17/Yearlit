import Foundation

#if canImport(PostHog)
  import PostHog
#endif

struct PostHogConfiguration {
  let projectToken: String?
  let host: String
  let enabledInDebug: Bool

  var isEnabled: Bool {
    guard let projectToken, !projectToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return false
    }

    #if DEBUG
      return enabledInDebug
    #else
      return true
    #endif
  }
}

final class PostHogAnalyticsClient: AnalyticsClient {
  private var distinctID: String?

  #if canImport(PostHog)
    init(configuration: PostHogConfiguration) {
      let config = PostHogConfig(
        projectToken: configuration.projectToken ?? "",
        host: configuration.host
      )
      config.captureApplicationLifecycleEvents = false
      config.captureScreenViews = false
      config.captureElementInteractions = false
      config.sessionReplay = false
      config.debug = false

      PostHogSDK.shared.setup(config)
    }
  #else
    init(configuration _: PostHogConfiguration) {}
  #endif

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    #if canImport(PostHog)
      PostHogSDK.shared.capture(event.rawValue, properties: properties.rawAnalyticsProperties)
    #endif
  }

  func identify(distinctId: String, properties: [String: AnalyticsPropertyValue]) {
    distinctID = distinctId
    #if canImport(PostHog)
      PostHogSDK.shared.identify(distinctId, userProperties: properties.rawAnalyticsProperties)
    #endif
  }

  func setPersonProperties(_ properties: [String: AnalyticsPropertyValue]) {
    guard let distinctID else { return }
    identify(distinctId: distinctID, properties: properties)
  }
}
