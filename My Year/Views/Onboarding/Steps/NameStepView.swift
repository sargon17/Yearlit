import SwiftUI

struct NameStepView: View {
  @Binding var name: String
  let onContinue: () -> Void
  let onSkip: () -> Void

  @FocusState private var isFocused: Bool
  @Environment(\.onboardingAccent) private var accent

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title("What should Yearlit call you?", lineLimit: 3)
        OnboardingView.Caption("This only makes the first habit feel more personal.")

        VStack(alignment: .leading, spacing: 8) {
          Text("Name")
            .labelStyle(type: .tertiary)

          TextField(
            "",
            text: $name,
            prompt: Text("Your name").foregroundColor(.white.opacity(0.2))
          )
          .focused($isFocused)
          .font(AppFont.mono(18, weight: .regular))
          .foregroundStyle(accent)
          .textContentType(.givenName)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .submitLabel(.continue)
          .onSubmit(onContinue)
        }
        .padding(14)
        .lcdScreenEffect(clipShape: RoundedRectangle(cornerRadius: 6), diffusion: 0.12, dotOpacity: 0.42)
        .sameLevelBorder(radius: 6, color: .black)
        .outerSameLevelShadow(radius: 6)
      }
    } actions: {
      VStack(spacing: 2) {
        OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)

        Button(action: onSkip) {
          Text("Skip")
            .font(AppFont.sans(16))
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
      }
    }
    .onAppear {
      isFocused = true
    }
  }
}
