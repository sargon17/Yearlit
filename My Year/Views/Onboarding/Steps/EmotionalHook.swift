import Garnish
import SharedModels
import SwiftUI

struct EmotionalHook: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingStepContainer {
      VStack {
        OnboardingView.ForwardButton(
          title: "Start my year",
          onTap: {
            onNext()
          })
        OnboardingView.ForwardButton(
          title: "Start my year",
          onTap: {
            onNext()
          },
          disabled: true,
        )
      }
      .padding()
    } content: {
      VStack(alignment: .leading) {
        OnboardingView.Title("Your year starts today")
        OnboardingView.Caption("Not January 1st. Not Monday.")
        OnboardingView.Caption("Your year starts when you show up.")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, 24)
    } actions: {
      OnboardingView.ForwardButton(
        title: "Start my year",
        onTap: {
          onNext()
        })
    }
  }
}
