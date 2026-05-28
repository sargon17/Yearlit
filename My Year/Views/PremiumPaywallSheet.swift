import SwiftUI

struct PremiumPaywallSheet: View {
  let displayCloseButton: Bool
  let trigger: PaywallTrigger

  init(displayCloseButton: Bool = false, trigger: PaywallTrigger) {
    self.displayCloseButton = displayCloseButton
    self.trigger = trigger
  }

  var body: some View {
    OnboardingPaywall(
      showsCloseButton: displayCloseButton,
      isPresentedAsSheet: true,
      trigger: trigger,
      onNext: {}
    )
  }
}
