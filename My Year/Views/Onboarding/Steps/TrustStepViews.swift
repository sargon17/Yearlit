import SwiftUI

struct WhyThisWorksView: View {
  let onContinue: () -> Void

  var body: some View {
    OnboardingStepContainer {
      OnboardingCalendarGridView()
        .background(.surfaceMuted)
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
      VStack(spacing: 14) {
        Image("founder-avatar")
          .resizable()
          .scaledToFill()
          .frame(width: 110, height: 110)
          .clipShape(Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.textPrimary.opacity(0.12), lineWidth: 1)
          }
          .shadow(color: .black.opacity(0.18), radius: 14, y: 6)

        VStack(spacing: 2) {
          Text("Mykhaylo")
            .font(AppFont.pixelCircle(22))
            .foregroundStyle(.textPrimary)

          Text("maker of Yearlit")
            .font(AppFont.sans(14))
            .foregroundStyle(.textSecondary)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Mykhaylo, maker of Yearlit")
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

  @Environment(\.onboardingAccent) private var accent

  var body: some View {
    OnboardingStepContainer {
      VStack(spacing: 32) {
        SocialProofStat(
          value: OnboardingCopy.appStoreRating,
          label: "App Store rating",
          size: 96
        )

        HStack(alignment: .top, spacing: 36) {
          SocialProofStat(
            value: OnboardingCopy.habitsTrackedStat,
            label: "habits tracked",
            size: 36,
            delay: 0.3
          )
          SocialProofStat(
            value: OnboardingCopy.dailyCheckInsStat,
            label: "daily check-ins",
            size: 36,
            delay: 0.5
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "Rated \(OnboardingCopy.appStoreRating) out of 5 on the App Store, \(OnboardingCopy.habitsTrackedStat) habits tracked, \(OnboardingCopy.dailyCheckInsStat) daily check-ins"
      )
    } content: {
      VStack(alignment: .leading, spacing: 12) {
        OnboardingView.Title(OnboardingCopy.socialProofTitle(for: motivation), lineLimit: 3)

        OnboardingView.Caption(
          "Rated \(OnboardingCopy.appStoreRating) out of 5 by hundreds of people worldwide."
        )
        OnboardingView.Caption(
          "People stay because it keeps things simple: show up, mark the day, keep going."
        )
      }
      .padding(.bottom, 16)
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}

private struct SocialProofStat: View {
  let value: String
  let label: LocalizedStringKey
  let size: CGFloat
  var delay: Double = 0

  @State private var shown = false

  @Environment(\.onboardingAccent) private var accent

  var body: some View {
    VStack(spacing: 6) {
      Text(shown ? value : zeroedValue)
        .font(AppFont.pixelCircle(size))
        .foregroundStyle(accent)
        .contentTransition(.numericText())
        .lineLimit(1)

      Text(label)
        .font(AppFont.sans(15))
        .foregroundStyle(.textSecondary)
    }
    .opacity(shown ? 1 : 0)
    .offset(y: shown ? 0 : 14)
    .onAppear {
      withAnimation(.spring(duration: 0.9).delay(delay)) {
        shown = true
      }
    }
  }

  private var zeroedValue: String {
    String(value.map { $0.isNumber ? "0" : $0 })
  }
}
