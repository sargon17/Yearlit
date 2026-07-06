import SwiftUI

struct MotivationView: View {
  let selectedMotivation: OnboardingMotivation?
  let onMotivationSelected: (OnboardingMotivation) -> Void
  let onNext: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title("What are you trying to change?", lineLimit: 3)
        OnboardingView.Caption("Yearlit will shape your first habit around that.")

        VStack(alignment: .leading, spacing: 2) {
          ForEach(OnboardingMotivation.allCases) { motivation in
            Button {
              onMotivationSelected(motivation)
            } label: {
              HStack {
                Text(motivation.title)
                  .frame(maxWidth: .infinity)
              }
              .padding()
              .foregroundStyle(.textPrimary)
              .sameLevelBorder(
                radius: 4,
                color: motivation == selectedMotivation ? .brand : .surfaceMuted,
                isFlat: true
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(2)
        .sameLevelGroupBackground()
      }
      .fixedSize(horizontal: false, vertical: true)
    } actions: {
      OnboardingView.ForwardButton(
        title: "Next",
        onTap: onNext,
        style: selectedMotivation == nil ? .disabled : .primary
      )
    }
  }
}
