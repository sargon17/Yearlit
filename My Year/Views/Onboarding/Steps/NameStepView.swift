import SwiftUI

struct NameStepView: View {
  @Binding var name: String
  let onContinue: () -> Void
  let onSkip: () -> Void

  @FocusState private var isFocused: Bool

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title("What should Yearlit call you?", lineLimit: 3)
        OnboardingView.Caption("This only makes the first habit feel more personal.")

        TextField("Your name", text: $name)
          .textContentType(.givenName)
          .textInputAutocapitalization(.words)
          .submitLabel(.continue)
          .focused($isFocused)
          .padding()
          .foregroundStyle(.textPrimary)
          .sameLevelBorder(radius: 4, color: .surfaceMuted, isFlat: true)
          .onSubmit(onContinue)
      }
    } actions: {
      VStack(spacing: 2) {
        OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
        OnboardingView.ForwardButton(title: "Skip", onTap: onSkip, style: .secondary)
      }
    }
    .onAppear {
      isFocused = true
    }
  }
}
