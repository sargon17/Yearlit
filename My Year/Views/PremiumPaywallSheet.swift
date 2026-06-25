import SwiftUI

struct PremiumPaywallSheet: View {
  let displayCloseButton: Bool
  let trigger: PaywallTrigger
  let analyticsProperties: [String: AnalyticsPropertyValue]

  init(
    displayCloseButton: Bool = false,
    trigger: PaywallTrigger,
    analyticsProperties: [String: AnalyticsPropertyValue] = [:]
  ) {
    self.displayCloseButton = displayCloseButton
    self.trigger = trigger
    self.analyticsProperties = analyticsProperties
  }

  var body: some View {
    OnboardingPaywall(
      showsCloseButton: displayCloseButton,
      isPresentedAsSheet: true,
      trigger: trigger,
      analyticsProperties: analyticsProperties,
      onNext: {}
    )
  }
}
