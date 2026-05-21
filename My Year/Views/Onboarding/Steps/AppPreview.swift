import Garnish
import SharedModels
import SwiftUI

struct AppPreview: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingStepContainer {
      GeometryReader { proxy in
        let size = max(proxy.size.width, proxy.size.height) * 1.15

        Image("onboarding_1")
          .resizable()
          .scaledToFit()
          .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
          .frame(width: size, height: size)
          .offset(y: proxy.size.height * 0.15)
      }
    } content: {
      VStack(alignment: .leading) {
        OnboardingView.Title("One dot. One day.")
        OnboardingView.Caption(
          "Each dot is one day in your year.")
        OnboardingView.Caption(
          "Tap today when you show up.")
        OnboardingView.Caption(
          "Watch your effort become visible.")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, 24)
    } actions: {
      OnboardingView.ForwardButton(
        title: "Show me",
        onTap: {
          onNext()
        })
    }
  }
}
