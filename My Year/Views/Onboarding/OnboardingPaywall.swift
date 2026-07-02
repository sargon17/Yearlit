import Garnish
import RevenueCat
import SwiftUI

struct OnboardingPaywall: View {
  let showsCloseButton: Bool
  let isPresentedAsSheet: Bool
  let trigger: PaywallTrigger
  let variant: PaywallVariant
  let motivation: OnboardingMotivation?
  let analyticsProperties: [String: AnalyticsPropertyValue]
  let onNext: () -> Void
  @StateObject private var purchaseModel: PaywallPurchaseModel
  @State private var didTrackClose = false
  @Environment(\.dismiss) private var dismiss
  @Environment(\.onboardingAccent) private var accent

  private var accentInverted: Color {
    (try? Garnish.contrastingShade(of: accent)) ?? .brandInverted
  }
  private let heroTopSpacing: CGFloat = 86

  init(
    showsCloseButton: Bool = true,
    isPresentedAsSheet: Bool = false,
    trigger: PaywallTrigger = .onboarding,
    variant: PaywallVariant? = nil,
    motivation: OnboardingMotivation? = nil,
    analyticsProperties: [String: AnalyticsPropertyValue] = [:],
    onNext: @escaping () -> Void
  ) {
    let resolvedVariant = variant ?? (trigger == .onboarding ? .commitmentProtectionV1 : .default)

    self.showsCloseButton = showsCloseButton
    self.isPresentedAsSheet = isPresentedAsSheet
    self.trigger = trigger
    self.variant = resolvedVariant
    self.motivation = motivation
    self.analyticsProperties = analyticsProperties
    self.onNext = onNext
    _purchaseModel = StateObject(
      wrappedValue: PaywallPurchaseModel(
        trigger: trigger,
        variant: resolvedVariant,
        analyticsProperties: analyticsProperties
      )
    )
  }
  var body: some View {
    OnboardingStepContainer(overlayHeight: 0.9, actionsBottomPadding: isPresentedAsSheet ? 4 : 16) {
      GeometryReader { proxy in
        ScrollView {
          PaywallHeroContent(motivation: motivation)
            .padding(.top, proxy.safeAreaInsets.top + heroTopSpacing)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollIndicators(.hidden)
      }
    } content: {
    } actions: {
      VStack {
        if purchaseModel.isLoading {
          PaywallLoadingCard()
        } else if purchaseModel.packages.isEmpty {
          PaywallEmptyCard(
            message: purchaseModel.errorMessage ?? String(localized: "Plans are unavailable right now.")
          )
        } else {
          VStack(spacing: 8) {
            ForEach(purchaseModel.packages, id: \.identifier) { package in
              PaywallPlanCard(
                package: package,
                comparisonPackage: comparisonPackage(for: package),
                isSelected: purchaseModel.selectedPackage?.identifier == package.identifier,
                onTap: { selectPackage(package) }
              )
            }
          }
        }

        if let errorMessage = purchaseModel.errorMessage, !purchaseModel.packages.isEmpty {
          Text(errorMessage)
            .font(AppFont.sans(12))
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Button {
          purchaseModel.purchaseSelectedPackage(onSuccess: closePaywall)
        } label: {
          HStack(spacing: 8) {
            if purchaseModel.isPurchasing {
              ProgressView()
                .tint(accentInverted)
            }

            Text(primaryButtonTitle)
              .font(AppFont.sans(18, weight: .bold))
          }
          .foregroundStyle(accentInverted)
          .frame(maxWidth: .infinity)
          .padding()
          .background(accent)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .disabled(
          purchaseModel.selectedPackage == nil || purchaseModel.isPurchasing || purchaseModel.isLoading
        )
        .opacity(purchaseModel.selectedPackage == nil || purchaseModel.isLoading ? 0.55 : 1)
        .sameLevelBorder(radius: 4, color: accent)

        PaywallFooterLinks {
          purchaseModel.restorePurchases(onActiveSubscription: closePaywall)
        }
      }
      .padding(.top, 4)
    }
    .overlay(alignment: .topLeading) {
      closeButtonOverlay
    }
    .task {
      await purchaseModel.loadPackages()
    }
    .onAppear {
      Analytics.shared.trackPaywallViewed(trigger: trigger, variant: variant, properties: analyticsProperties)
    }
    .onDisappear {
      trackCloseIfNeeded()
    }
  }

  @ViewBuilder
  private var closeButtonOverlay: some View {
    if showsCloseButton {
      Button {
        closePaywall()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.textSecondary.opacity(0.6))
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.top, 44)
      .padding(.trailing, 8)
      .accessibilityLabel("Close paywall")
      .zIndex(100)
    }
  }

  private var primaryButtonTitle: String {
    purchaseModel.primaryButtonTitle
  }

  private func closePaywall() {
    trackCloseIfNeeded()
    onNext()
    dismiss()
  }

  private func trackCloseIfNeeded() {
    guard !didTrackClose else { return }
    didTrackClose = true
    Analytics.shared.trackPaywallClosed(trigger: trigger, variant: variant, properties: analyticsProperties)
  }

  private func selectPackage(_ package: Package) {
    guard purchaseModel.selectedPackageID != package.identifier else { return }

    purchaseModel.selectedPackageID = package.identifier
    Analytics.shared.trackPaywallPackageSelected(
      trigger: trigger,
      variant: variant,
      package: package.paywallAnalyticsContext,
      properties: analyticsProperties
    )
  }

  private func comparisonPackage(for package: Package) -> Package? {
    guard package.packageType == .annual else { return nil }

    return purchaseModel.packages.first { $0.packageType == .weekly }
      ?? purchaseModel.packages.first { $0.packageType == .monthly }
  }
}
