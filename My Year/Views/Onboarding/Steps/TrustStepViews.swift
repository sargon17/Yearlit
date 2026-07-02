import SwiftUI

struct WhyThisWorksView: View {
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingView.Title("Tiny beats perfect")
        OnboardingView.Caption(
          "Reliable habits are easier to build when the action is small, visible, and repeatable."
        )
        OnboardingView.Caption("Yearlit keeps the focus simple: one habit, one day, one visible proof.")
      }
      .padding(.bottom, 24)
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}

struct FounderNoteView: View {
  let motivation: OnboardingMotivation?
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 10) {
        OnboardingView.Title("A note from the founder", lineLimit: 3)
        OnboardingView.Caption(
          "I built Yearlit because missing one day should not erase the year you are trying to build.")
        OnboardingView.Caption(OnboardingCopy.founderMiddleLine(for: motivation))
        OnboardingView.Caption("Your first habit is already here. One dot is enough to begin.")
      }
      .padding(.bottom, 24)
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}

struct SocialProofView: View {
  let motivation: OnboardingMotivation?
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title(OnboardingCopy.socialProofTitle(for: motivation), lineLimit: 3)

        VStack(alignment: .leading, spacing: 2) {
          SocialProofRow(title: "App Store rating", value: "\(OnboardingCopy.appStoreRating) stars")
          SocialProofRow(title: "Early ratings", value: "\(OnboardingCopy.appStoreRatingCount)")
        }
        .padding(2)
        .sameLevelGroupBackground()

        OnboardingView.Caption(
          "People use Yearlit because it stays simple: show up, mark the day, keep going."
        )
      }
      .padding(.bottom, 16)
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}

private struct SocialProofRow: View {
  let title: LocalizedStringKey
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .font(AppFont.sans(16))
        .foregroundStyle(.textSecondary)

      Spacer()

      Text(value)
        .font(AppFont.pixelCircle(24))
        .foregroundStyle(Color.brand)
    }
    .padding()
    .sameLevelBorder(radius: 4, color: .surfaceMuted, isFlat: true)
  }
}
