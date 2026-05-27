import RevenueCatUI
import SwiftUI

struct PremiumPaywallSheet: View {
  let displayCloseButton: Bool
  let trigger: PaywallTrigger

  init(displayCloseButton: Bool = false, trigger: PaywallTrigger) {
    self.displayCloseButton = displayCloseButton
    self.trigger = trigger
  }

  var body: some View {
    PaywallView(displayCloseButton: displayCloseButton)
      .ignoresSafeArea(.container, edges: .bottom)
      .onAppear {
        Analytics.shared.trackPaywallViewed(trigger: trigger)
      }
  }
}
