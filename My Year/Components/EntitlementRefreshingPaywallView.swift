import RevenueCatUI
import SwiftUI

struct EntitlementRefreshingPaywallView: View {
  @EnvironmentObject private var entitlements: EntitlementManager

  let displayCloseButton: Bool

  init(displayCloseButton: Bool = false) {
    self.displayCloseButton = displayCloseButton
  }

  var body: some View {
    PaywallView(displayCloseButton: displayCloseButton)
      .onDisappear {
        Task {
          await entitlements.refresh()
        }
      }
  }
}
