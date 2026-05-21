import Garnish
import SwiftUI

struct ReviewRequestView: View {
  let isRequestingReview: Bool
  let onLeaveReview: () -> Void
  let onNotNow: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()
        Text("Review request")
          .font(AppFont.pixelCircle(24))
          .foregroundStyle(.textPrimary)
        Text(isRequestingReview ? "Opening the review prompt…" : "If the system shows a prompt, use it now.")
          .font(AppFont.mono(14))
          .foregroundStyle(.secondary)
      }
    } actions: {
      VStack(spacing: 12) {
        OnboardingView.ForwardButton(
          title: isRequestingReview ? "Opening…" : "Leave a review",
          onTap: onLeaveReview,
          style: isRequestingReview ? .disabled : .primary
        )
        OnboardingView.ForwardButton(
            title: "Not now",
            onTap: onNotNow,
            style: isRequestingReview ? .disabled : .primary)
      }
    }
  }
}
