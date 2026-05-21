import SwiftUI

extension OnboardingView {
  struct GradientOverlay: View {
    var body: some View {
      LinearGradient(
        gradient: Gradient(colors: [Color.clear, .surfaceMuted]),
        startPoint: .init(x: 0.5, y: 0.6),
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }
}
