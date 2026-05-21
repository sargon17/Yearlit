import Garnish
import SwiftUI

enum IdentityCommitment: String, CaseIterable, Identifiable, Hashable {
  case reader = "reads"
  case strengthTrainer = "trains"
  case writer = "writes"
  case meditator = "meditate"
  case learner = "learn"
  case saver = "saves money"
  case creator = "creates"
  case earlyBird = "wakes early"

  var id: String { rawValue }
  var title: String { rawValue }
}

struct IdentityFirst: View {
  let selectedCommitments: [IdentityCommitment]
  let onCommitmentTapped: (IdentityCommitment) -> Void
  let canContinue: Bool
  let onNext: () -> Void

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    OnboardingStepContainer {
      ZStack {

      }
    } content: {
      VStack(alignment: .leading, ) {
        OnboardingView.Title("I'm becoming someone who...")
        VStack {

          LazyVGrid(
            columns: [
              GridItem(.flexible(), spacing: 2),
              GridItem(.flexible(), spacing: 2)
            ], spacing: 2
          ) {
            ForEach(IdentityCommitment.allCases) { commitment in
              Button {
                onCommitmentTapped(commitment)
              } label: {
                HStack {
                  Text(commitment.title)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundStyle(.textPrimary)
                .sameLevelBorder(
                  radius: 4,
                  color: selectedCommitments.contains(commitment) ? .brand : .surfaceMuted,
                  isFlat: true
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(2)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .foregroundStyle(.black)
        )

        OnboardingView.Caption("Choose the promise you want to keep this year.")
        OnboardingView.Caption("Yearlit will help you prove it, one day at a time.")
      }
    } actions: {
      OnboardingView.ForwardButton(title: "Next", onTap: onNext, disabled: !canContinue)
    }
  }
}
