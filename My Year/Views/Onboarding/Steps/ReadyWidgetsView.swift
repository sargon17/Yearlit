import Garnish
import SwiftUI

struct ReadyWidgetsView: View {
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading) {
        OnboardingView.Title("Everything is ready")
        OnboardingView.Caption("Your first habit is set.")
        OnboardingView.Caption("Add a Yearlit widget to keep your promise where you’ll see it.")
          .padding(.bottom)
        OnboardingView.Caption("The more visible your habit is, the easier it is to return.")
      }
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}
