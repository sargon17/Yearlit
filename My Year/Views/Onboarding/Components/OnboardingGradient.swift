import SwiftUI

extension OnboardingView {
  struct GradientOverlay: View {
    let height: CGFloat

    init(height: CGFloat = 0.6) {
      self.height = height
    }

    var body: some View {
      LinearGradient(
        gradient: Gradient(colors: [Color.clear, .surfaceMuted]),
        startPoint: .init(x: 0.5, y: height),
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }
}
