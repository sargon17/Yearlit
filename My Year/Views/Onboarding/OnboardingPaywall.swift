import RevenueCatUI
import SwiftUI

struct OnboardingPaywall: View {
  let onNext: () -> Void

  var body: some View {
    ZStack {
      VStack {
        PaywallView()
      }
      .clipped()
    }
    .overlay(
      HStack {
        Spacer()
        Button(action: {
          onNext()
        }) {
          Image(systemName: "xmark")
            .foregroundColor(.textSecondary)
            .padding(8)
        }
      }
      .padding(),
      alignment: .topTrailing
    )
  }
}
