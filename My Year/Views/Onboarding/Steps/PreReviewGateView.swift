import Garnish
import SwiftUI

struct PreReviewGateView: View {
  let onPositive: () -> Void
  let onSkip: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingView.Title("How does your first dot feel?")
        OnboardingView.Caption("You’ve just started your year.")
        OnboardingView.Caption("Does seeing Day 1 make the habit feel more real?")
      }
    } actions: {
      VStack(spacing: 2) {
        OnboardingView.ForwardButton(title: "Feels motivating", onTap: onPositive, style: .secondary)
        OnboardingView.ForwardButton(title: "It’s clear", onTap: onPositive, style: .secondary)
        OnboardingView.ForwardButton(title: "Not yet", onTap: onSkip, style: .secondary)
      }
    }
  }
}
