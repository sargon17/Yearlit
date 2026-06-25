import RevenueCat
import SwiftUI

struct OnboardingPaywall: View {
  let showsCloseButton: Bool
  let isPresentedAsSheet: Bool
  let trigger: PaywallTrigger
  let analyticsProperties: [String: AnalyticsPropertyValue]
  let onNext: () -> Void
  @StateObject private var purchaseModel = PaywallPurchaseModel()
  @State private var didTrackTerminalAction = false
  @Environment(\.dismiss) private var dismiss
  private let heroTopSpacing: CGFloat = 86

  init(
    showsCloseButton: Bool = true,
    isPresentedAsSheet: Bool = false,
    trigger: PaywallTrigger = .onboarding,
    analyticsProperties: [String: AnalyticsPropertyValue] = [:],
    onNext: @escaping () -> Void
  ) {
    self.showsCloseButton = showsCloseButton
    self.isPresentedAsSheet = isPresentedAsSheet
    self.trigger = trigger
    self.analyticsProperties = analyticsProperties
    self.onNext = onNext
  }
  var body: some View {
    OnboardingStepContainer(overlayHeight: 0.9, actionsBottomPadding: isPresentedAsSheet ? 4 : 16) {
      GeometryReader { proxy in
        ScrollView {
          PaywallHeroContent()
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
                isSelected: purchaseModel.selectedPackage?.identifier == package.identifier,
                onTap: { purchaseModel.selectedPackageID = package.identifier }
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
          Analytics.shared.trackPaywallAction(.primaryTapped, trigger: trigger, properties: analyticsProperties)
          purchaseModel.purchaseSelectedPackage(
            onSuccess: {
              closePaywall(action: .purchaseCompleted)
            },
            onCancel: {
              Analytics.shared.trackPaywallAction(.purchaseCancelled, trigger: trigger, properties: analyticsProperties)
            },
            onFailure: {
              Analytics.shared.trackPaywallAction(.purchaseFailed, trigger: trigger, properties: analyticsProperties)
            }
          )
        } label: {
          HStack(spacing: 8) {
            if purchaseModel.isPurchasing {
              ProgressView()
                .tint(.brandInverted)
            }

            Text(primaryButtonTitle)
              .font(AppFont.sans(18, weight: .bold))
          }
          .foregroundStyle(Color.brandInverted)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.brand)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .disabled(
          purchaseModel.selectedPackage == nil || purchaseModel.isPurchasing || purchaseModel.isLoading
        )
        .opacity(purchaseModel.selectedPackage == nil || purchaseModel.isLoading ? 0.55 : 1)
        .sameLevelBorder(radius: 4, color: .brand)

        PaywallFooterLinks {
          Analytics.shared.trackPaywallAction(.restoreTapped, trigger: trigger, properties: analyticsProperties)
          purchaseModel.restorePurchases(
            onActiveSubscription: {
              closePaywall(action: .restoreCompleted)
            },
            onFailure: {
              Analytics.shared.trackPaywallAction(.restoreFailed, trigger: trigger, properties: analyticsProperties)
            }
          )
        }
      }
      .padding(.top, 4)
    }
    .overlay(alignment: .topTrailing) {
      closeButtonOverlay
    }
    .task {
      await purchaseModel.loadPackages()
    }
    .onAppear {
      Analytics.shared.trackPaywallViewed(trigger: trigger, properties: analyticsProperties)
    }
    .onDisappear {
      guard !didTrackTerminalAction else { return }
      didTrackTerminalAction = true
      Analytics.shared.trackPaywallAction(.dismissed, trigger: trigger, properties: analyticsProperties)
    }
  }

  @ViewBuilder
  private var closeButtonOverlay: some View {
    if showsCloseButton {
      Button {
        closePaywall(action: .dismissed)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.textSecondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .modifier(PaywallCloseButtonSurface())
      .padding(.top, 44)
      .padding(.trailing, 8)
      .accessibilityLabel("Close paywall")
      .zIndex(100)
    }
  }

  private var primaryButtonTitle: String {
    purchaseModel.primaryButtonTitle
  }

  private func closePaywall(action: PaywallAction) {
    didTrackTerminalAction = true
    Analytics.shared.trackPaywallAction(action, trigger: trigger, properties: analyticsProperties)
    onNext()
    dismiss()
  }
}

private struct PaywallCloseButtonSurface: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(.regular.interactive(), in: .circle)
    } else {
      content
        .background(.surfaceMuted.opacity(0.75), in: Circle())
    }
  }
}

private struct PaywallHeroContent: View {
  var body: some View {
    VStack(alignment: .leading) {
      OnboardingView.Title("Build your year with Pro.", lineLimit: 3)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 4) {
        OnboardingView.Caption("Keep your habits visible with widgets, unlimited")
        OnboardingView.Caption("tracking, and tools built for consistency.")
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 22) {
        PaywallFeatureRow(title: "Deeper stats", subtitle: "see patterns over time")
        PaywallFeatureRow(title: "Unlimited habits", subtitle: "track every promise")
        PaywallFeatureRow(title: "Widgets", subtitle: "keep your dots on your Home Screen")
        PaywallFeatureRow(
          title: "Support a solo-built app",
          subtitle: "Your upgrade helps me keep building Yearlit."
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
              Text(priceLine)
                .font(AppFont.sans(16, weight: .semibold))
                .foregroundStyle(.textPrimary)

              if let badge {
                Text(badge)
                  .font(AppFont.pixelCircle(14))
                  .foregroundStyle(Color.brand)
              }
            }
          }

          Spacer()

          if isSelected {
            Image(systemName: "checkmark")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(Color.brandInverted)
              .frame(width: 28, height: 28)
              .background(Color.brand)
              .clipShape(Circle())
          }
        }

        if isFeatured {
          Spacer()
        }

        Text(footer)
          .font(AppFont.sans(16))
          .foregroundStyle(.textPrimary.opacity(0.8))
      }
      .frame(maxWidth: .infinity, maxHeight: isFeatured ? 156 : nil, alignment: .leading)
      .padding(12)
      .background(.surfaceMuted)
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    .buttonStyle(.plain)
    .sameLevelBorder(radius: 4, isFlat: isSelected)
  }

  private var isFeatured: Bool {
    package.packageType == .annual
  }

  private var title: String {
    switch package.packageType {
    case .annual: return String(localized: "Yearly")
    case .weekly: return String(localized: "Weekly")
    case .monthly: return String(localized: "Monthly")
    default: return package.storeProduct.localizedTitle.nilIfEmpty ?? "Pro"
    }
  }

  private var priceLine: String {
    if let trialText {
      return String(localized: "\(trialText), then \(package.localizedPriceString)\(periodSuffix)")
    }

    return "\(package.localizedPriceString)\(periodSuffix)"
  }

  private var periodSuffix: String {
    switch package.packageType {
    case .annual: return String(localized: "/year")
    case .weekly: return String(localized: "/week")
    case .monthly: return String(localized: "/month")
    default: return ""
    }
  }

  private var trialText: String? {
    guard
      let intro = package.storeProduct.introductoryDiscount,
      intro.paymentMode == .freeTrial
    else { return nil }

    let value = intro.subscriptionPeriod.value * intro.numberOfPeriods
    let unit = intro.subscriptionPeriod.unit.paywallUnitName(for: value)
    return String(localized: "\(value) \(unit) free")
  }

  private var badge: String? {
    package.packageType == .annual ? String(localized: "Save 51%") : nil
  }

  private var footer: String {
    switch package.packageType {
    case .annual: return String(localized: "Best for building consistency")
    case .weekly: return String(localized: "Flexible access")
    case .monthly: return String(localized: "Simple monthly plan")
    default: return String(localized: "Unlock every Pro tool")
    }
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

  var body: some View {
    HStack(spacing: 14) {
      Button(action: onRestore) {
        footerLabel("Restore purchases")
      }

      Link(destination: URL(string: "https://tymofyeyev.com/yearlit/terms")!) {
        footerLabel("Terms")
      }

      Link(destination: URL(string: "https://tymofyeyev.com/yearlit/privacy-policy")!) {
        footerLabel("Privacy")
      }
    }
    .foregroundStyle(.textSecondary)
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
  }

  private func footerLabel(_ title: LocalizedStringKey) -> some View {
    Text(title)
      .font(AppFont.sans(12))
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
  }
}

extension SubscriptionPeriod.Unit {
  fileprivate func paywallUnitName(for value: Int) -> String {
    switch self {
    case .day: return value == 1 ? String(localized: "day") : String(localized: "days")
    case .week: return value == 1 ? String(localized: "week") : String(localized: "weeks")
    case .month: return value == 1 ? String(localized: "month") : String(localized: "months")
    case .year: return value == 1 ? String(localized: "year") : String(localized: "years")
    @unknown default: return String(localized: "days")
    }
  }
}

extension String {
  fileprivate var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
