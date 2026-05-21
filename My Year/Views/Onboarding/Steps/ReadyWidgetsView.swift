import Garnish
import SwiftUI

struct ReadyWidgetsView: View {
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()
        Text("Widgets are ready.")
          .font(AppFont.pixelCircle(24))
          .foregroundStyle(.textPrimary)
        Text("Put the habit on your home screen.")
          .font(AppFont.mono(14))
          .foregroundStyle(.secondary)
      }
    } actions: {
      OnboardingView.ForwardButton(title: "Continue to paywall", onTap: onContinue)
    }
  }
}
