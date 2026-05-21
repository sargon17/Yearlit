import Garnish
import SwiftUI

struct PreReviewGateView: View {
  let onPositive: () -> Void
  let onNotNow: () -> Void
  let onSkip: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()
        Text("How did that first dot feel?")
          .font(AppFont.pixelCircle(24))
          .foregroundStyle(.textPrimary)
        Text("Pick the closest answer.")
          .font(AppFont.mono(14))
          .foregroundStyle(.secondary)
      }
    } actions: {
      VStack(spacing: 12) {
        OnboardingView.ForwardButton(title: "Great", onTap: onPositive)
        OnboardingView.ForwardButton(title: "Fine", onTap: onNotNow)
        OnboardingView.ForwardButton(title: "Not now", onTap: onSkip)
      }
    }
  }
}
