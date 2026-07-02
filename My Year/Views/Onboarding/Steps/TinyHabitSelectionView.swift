import Garnish
import SwiftUI

struct TinyHabitSelectionView: View {
  let habits: [String]
  let selectedHabit: String?
  @Binding var selectedColor: String
  let onHabitSelected: (String) -> Void
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear

    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title("Make it tiny.")

        VStack(alignment: .leading, spacing: 2) {
          ForEach(habits, id: \.self) { habit in
            Button {
              onHabitSelected(habit)
            } label: {
              HStack {
                Text(habit)
                  .frame(maxWidth: .infinity)
              }
              .padding()
              .foregroundStyle(.textPrimary)
              .sameLevelBorder(
                radius: 4,
                color: habit == selectedHabit ? Color(selectedColor) : .surfaceMuted,
                isFlat: true
              )

            }
            .buttonStyle(.plain)
          }
        }.padding(2)
          .sameLevelGroupBackground()

        OnboardingView.Caption("Start with something small enough to do even on a hard day.")

        VStack(alignment: .leading, spacing: 2) {
          Text("Color")
            .labelStyle(type: .tertiary)
            .padding(.horizontal, 14)
            .padding(.top, 12)

          ColorSwatchPicker(
            selectedColor: $selectedColor,
            accessibilityHint: "Select onboarding habit color",
            isScreenStyled: false
          )
        }
        .padding(.bottom, 2)
        .lcdScreenEffect(clipShape: RoundedRectangle(cornerRadius: 6), diffusion: 0.12, dotOpacity: 0.42)
        .sameLevelBorder(radius: 6, color: .black)
        .outerSameLevelShadow(radius: 6)
      }
    } actions: {
      OnboardingView.ForwardButton(
        title: "Create my habit", onTap: onContinue, style: selectedHabit == nil ? .disabled : .primary)
    }
  }
}
