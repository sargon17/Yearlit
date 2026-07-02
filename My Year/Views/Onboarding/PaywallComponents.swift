import RevenueCat
import SwiftUI

struct PaywallHeroContent: View {
  let motivation: OnboardingMotivation?

  init(motivation: OnboardingMotivation? = nil) {
    self.motivation = motivation
  }

  var body: some View {
    VStack(alignment: .leading) {
      OnboardingView.Title(OnboardingCopy.paywallTitle(for: motivation), lineLimit: 3)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 4) {
        OnboardingView.Caption("Your first habit is ready.")
        OnboardingView.Caption(OnboardingCopy.paywallSubtitle(for: motivation))
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 22) {
        PaywallFeatureRow(
          title: "Keep your first habit visible", subtitle: "widgets put your promise where you will see it")
        PaywallFeatureRow(
          title: "See the pattern behind your streak",
          subtitle: "stats show what is working before motivation fades"
        )
        PaywallFeatureRow(
          title: "Track every promise",
          subtitle: "unlimited calendars for every habit that matters"
        )
        PaywallFeatureRow(
          title: "Start free, stay in control",
          subtitle: "try Pro and cancel anytime from your App Store subscription settings"
        )
      }
      .padding(.top, 34)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct PaywallFeatureRow: View {
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(AppFont.pixelCircle(24))
        .foregroundStyle(Color.brand)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text(subtitle)
        .font(AppFont.sans(18))
        .foregroundStyle(.textSecondary.opacity(0.5))
        .lineLimit(3)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct PaywallPlanCard: View {
  let package: Package
  let comparisonPackage: Package?
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button {
      onTap()
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 8) {
            Text(title)
              .font(AppFont.sans(18, weight: .bold))
              .foregroundStyle(isSelected ? Color.brand : Color.textPrimary)

            HStack(spacing: 10) {
              if let comparisonPriceLine {
                Text(comparisonPriceLine)
                  .font(AppFont.sans(15, weight: .semibold))
                  .foregroundStyle(.textSecondary.opacity(0.55))
                  .strikethrough(true, color: .textSecondary.opacity(0.55))

                Text(currentPriceLine)
                  .font(AppFont.sans(16, weight: .bold))
                  .foregroundStyle(.textPrimary)
              } else {
                Text(priceLine)
                  .font(AppFont.sans(16, weight: .semibold))
                  .foregroundStyle(.textPrimary)
              }

              if let badge {
                Text(badge)
                  .font(AppFont.sans(14, weight: .bold))
                  .padding(.horizontal, 4)
                  .padding(.vertical, 2)
                  .foregroundStyle(Color.surfaceMuted)
                  .background(Color.brand)
              }
            }

            if let trialLine {
              Text(trialLine)
                .font(AppFont.sans(13, weight: .semibold))
                .foregroundStyle(.textSecondary.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
          }

          Spacer()
        }

        if isFeatured {
          Spacer()
        }

        Text(footer)
          .font(AppFont.sans(12))
          .foregroundStyle(.textSecondary.opacity(0.8))
      }
      .frame(maxWidth: .infinity, maxHeight: isFeatured ? 156 : nil, alignment: .leading)
      .padding(12)
      .background(.surfaceMuted)
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    .buttonStyle(.plain)
    .sameLevelBorder(radius: 4, isFlat: isSelected)
  }

}

struct PaywallLoadingCard: View {
  var body: some View {
    HStack(spacing: 12) {
      ProgressView()
        .tint(.brand)
      Text("Loading plans…")
        .font(AppFont.sans(16))
        .foregroundStyle(.textPrimary)
      Spacer()
    }
    .padding(18)
    .frame(maxWidth: .infinity)
    .background(.surfaceMuted)
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .sameLevelBorder(radius: 4, color: .textSecondary.opacity(0.28))
  }
}

struct PaywallEmptyCard: View {
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Plans unavailable")
        .font(AppFont.sans(18, weight: .bold))
        .foregroundStyle(.textPrimary)
      Text(message)
        .font(AppFont.sans(14))
        .foregroundStyle(.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(.surfaceMuted)
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .sameLevelBorder(radius: 4, color: .textSecondary.opacity(0.28))
  }
}

struct PaywallFooterLinks: View {
  let onRestore: () -> Void

  private let termsURL = URL(string: "https://tymofyeyev.com/yearlit/terms")
  private let privacyURL = URL(string: "https://tymofyeyev.com/yearlit/privacy-policy")

  var body: some View {
    HStack(spacing: 14) {
      Button(action: onRestore) {
        footerLabel("Restore purchases")
      }

      if let termsURL {
        Link(destination: termsURL) {
          footerLabel("Terms")
        }
      }

      if let privacyURL {
        Link(destination: privacyURL) {
          footerLabel("Privacy")
        }
      }
    }
    .foregroundStyle(.textSecondary)
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
    .padding(.bottom, -12)
  }

  private func footerLabel(_ title: LocalizedStringKey) -> some View {
    Text(title)
      .font(AppFont.sans(12))
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      .contentShape(Rectangle())
  }
}
