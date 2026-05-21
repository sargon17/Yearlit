import Garnish
import SharedModels
import SwiftUI

struct FirstDotView: View {
  let calendar: CustomCalendar?
  let isCompletedToday: Bool
  let canMarkDayOne: Bool
  let onMarkDayOne: () -> Void
  let onContinue: () -> Void
  @State private var animatedCompletion = false

  private var showingProofState: Bool {
    isCompletedToday || animatedCompletion
  }

  var body: some View {
    OnboardingStepContainer {
      VStack(spacing: 18) {
        Circle()
          .fill(showingProofState ? Color.brand : Color.surfaceMuted)
          .frame(width: 96, height: 96)
          .scaleEffect(showingProofState ? 1.04 : 0.9)
          .overlay {
            Circle()
              .strokeBorder(Color.brand, lineWidth: 2)
              .opacity(showingProofState ? 1 : 0.25)
          }
          .shadow(color: Color.brand.opacity(showingProofState ? 0.22 : 0), radius: 16, y: 6)

        if showingProofState {
          Text("Proof added")
            .font(AppFont.pixelCircle(18))
            .foregroundStyle(.textPrimary)
        }
      }
      .padding(.top, 24)
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        Text("Make the first dot.")
          .font(AppFont.pixelCircle(24))
          .foregroundStyle(.textPrimary)
        Text(showingProofState ? "Day 1 is in place." : "A single completed day is enough to start.")
          .font(AppFont.mono(14))
          .foregroundStyle(.secondary)
      }
    } actions: {
      if showingProofState {
        OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
      } else {
        OnboardingView.ForwardButton(
          title: "Mark Day 1",
          onTap: onMarkDayOne,
          disabled: !canMarkDayOne || calendar == nil
        )
      }
    }
    .onChange(of: isCompletedToday) { _, newValue in
      withAnimation(.easeInOut(duration: 0.22)) {
        animatedCompletion = newValue
      }
    }
    .onAppear {
      animatedCompletion = isCompletedToday
    }
  }
}
