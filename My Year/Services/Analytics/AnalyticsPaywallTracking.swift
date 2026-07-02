import Foundation

@MainActor
extension Analytics {
  func trackPaywallPromptConsidered(
    trigger: PaywallTrigger,
    result: String,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallPromptConsidered,
      properties: properties.merging([
        "paywall_trigger": .string(trigger.rawValue),
        "result": .string(result)
      ]) { _, new in new }
    )
  }

  func trackPaywallViewed(
    trigger: PaywallTrigger,
    variant: PaywallVariant = .default,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallViewed,
      properties: paywallProperties(trigger: trigger, variant: variant, properties: properties)
    )
  }

  func trackPaywallPackageSelected(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallPackageSelected,
      properties: paywallPackageProperties(
        trigger: trigger,
        variant: variant,
        package: package,
        properties: properties
      )
    )
  }

  func trackPaywallPurchaseStarted(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallPurchaseStarted,
      properties: paywallPackageProperties(
        trigger: trigger,
        variant: variant,
        package: package,
        properties: properties
      )
    )
  }

  func trackPaywallPurchaseSucceeded(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallPurchaseSucceeded,
      properties: paywallPackageProperties(
        trigger: trigger,
        variant: variant,
        package: package,
        properties: properties
      )
    )
  }

  func trackPaywallPurchaseCancelled(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    var eventProperties = paywallPackageProperties(
      trigger: trigger,
      variant: variant,
      package: package,
      properties: properties
    )
    eventProperties["is_user_cancelled"] = .bool(true)
    track(.paywallPurchaseCancelled, properties: eventProperties)
  }

  func trackPaywallPurchaseFailed(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    errorCategory: PaywallErrorCategory,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    var eventProperties = paywallPackageProperties(
      trigger: trigger,
      variant: variant,
      package: package,
      properties: properties
    )
    eventProperties["error_category"] = .string(errorCategory.rawValue)
    track(.paywallPurchaseFailed, properties: eventProperties)
  }

  func trackPaywallRestoreStarted(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallRestoreStarted,
      properties: paywallProperties(trigger: trigger, variant: variant, properties: properties)
    )
  }

  func trackPaywallRestoreSucceeded(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallRestoreSucceeded,
      properties: paywallProperties(trigger: trigger, variant: variant, properties: properties)
    )
  }

  func trackPaywallRestoreFailed(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    errorCategory: PaywallErrorCategory,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    var eventProperties = paywallProperties(
      trigger: trigger,
      variant: variant,
      properties: properties
    )
    eventProperties["error_category"] = .string(errorCategory.rawValue)
    track(.paywallRestoreFailed, properties: eventProperties)
  }

  func trackPaywallClosed(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) {
    track(
      .paywallClosed,
      properties: paywallProperties(trigger: trigger, variant: variant, properties: properties)
    )
  }

  private func paywallProperties(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) -> [String: AnalyticsPropertyValue] {
    properties.merging([
      "paywall_trigger": .string(trigger.rawValue),
      "paywall_variant": .string(variant.rawValue)
    ]) { _, new in new }
  }

  private func paywallPackageProperties(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    package: PaywallPackageAnalyticsContext,
    properties: [String: AnalyticsPropertyValue] = [:]
  ) -> [String: AnalyticsPropertyValue] {
    var eventProperties = paywallProperties(trigger: trigger, variant: variant, properties: properties)
    eventProperties["package_identifier"] = .string(package.identifier)
    eventProperties["package_type"] = .string(package.type.rawValue)
    eventProperties["has_free_trial"] = .bool(package.hasFreeTrial)
    if let localizedPrice = package.localizedPrice {
      eventProperties["localized_price"] = .string(localizedPrice)
    }
    return eventProperties
  }
}
