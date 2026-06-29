import Garnish
import SwiftUI

struct TinyHabitSelectionView: View {
  let habits: [String]
  let selectedHabit: String?
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
              .sameLevelBorder(radius: 4, color: habit == selectedHabit ? .brand : .surfaceMuted, isFlat: true)

            }
            .buttonStyle(.plain)
          }
        }.padding(2)
          .sameLevelGroupBackground()

        OnboardingView.Caption("Start with something small enough to do even on a hard day.")
      }
    } actions: {
      OnboardingView.ForwardButton(
        title: "Create my habit", onTap: onContinue, style: selectedHabit == nil ? .disabled : .primary)
    }
  }
}
