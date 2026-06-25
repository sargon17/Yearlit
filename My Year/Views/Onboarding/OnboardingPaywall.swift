import RevenueCat
import SwiftUI

struct OnboardingPaywall: View {
  let showsCloseButton: Bool
  let isPresentedAsSheet: Bool
  let trigger: PaywallTrigger
  let variant: PaywallVariant
  let onNext: () -> Void
  @StateObject private var purchaseModel: PaywallPurchaseModel
  @Environment(\.dismiss) private var dismiss
  private let heroTopSpacing: CGFloat = 86

  init(
    showsCloseButton: Bool = true,
    isPresentedAsSheet: Bool = false,
    trigger: PaywallTrigger = .onboarding,
    variant: PaywallVariant? = nil,
    onNext: @escaping () -> Void
  ) {
    let resolvedVariant = variant ?? (trigger == .onboarding ? .commitmentProtectionV1 : .default)

    self.showsCloseButton = showsCloseButton
    self.isPresentedAsSheet = isPresentedAsSheet
    self.trigger = trigger
    self.variant = resolvedVariant
    self.onNext = onNext
    _purchaseModel = StateObject(
      wrappedValue: PaywallPurchaseModel(trigger: trigger, variant: resolvedVariant)
    )
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
      Analytics.shared.trackPaywallViewed(trigger: trigger, variant: variant)
    }
  }

  @ViewBuilder
  private var closeButtonOverlay: some View {
    if showsCloseButton {
      Button(action: closePaywall) {
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
    Analytics.shared.trackPaywallClosed(trigger: trigger, variant: variant)
    onNext()
    dismiss()
  }

  private func selectPackage(_ package: Package) {
    guard purchaseModel.selectedPackageID != package.identifier else { return }

    purchaseModel.selectedPackageID = package.identifier
    Analytics.shared.trackPaywallPackageSelected(
      trigger: trigger,
      variant: variant,
      package: package.paywallAnalyticsContext
    )
  }

  private func comparisonPackage(for package: Package) -> Package? {
    guard package.packageType == .annual else { return nil }

    return purchaseModel.packages.first { $0.packageType == .weekly }
      ?? purchaseModel.packages.first { $0.packageType == .monthly }
  }
}

private struct PaywallHeroContent: View {
  var body: some View {
    VStack(alignment: .leading) {
      OnboardingView.Title("Protect the year you just started.", lineLimit: 3)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .leading, spacing: 4) {
        OnboardingView.Caption("Your first habit is ready.")
        OnboardingView.Caption("Pro helps you keep it visible, track the pattern, and come back tomorrow.")
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

  private var isFeatured: Bool {
    package.packageType == .annual
  }

  private var title: String {
    switch package.packageType {
    case .annual: return String(localized: "Yearly")
    case .weekly: return String(localized: "Weekly")
    case .monthly: return String(localized: "Monthly")
    default: return package.storeProduct.localizedTitle.nilIfEmpty ?? String(localized: "Pro")
    }
  }

  private var priceLine: String {
    if let trialText {
      return String(localized: "\(trialText), then \(package.localizedPriceString)\(periodSuffix)")
    }

    return "\(package.localizedPriceString)\(periodSuffix)"
  }

  private var currentPriceLine: String {
    "\(package.localizedPriceString)\(periodSuffix)"
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
    guard let discountPercentage else { return nil }
    return "-\(discountPercentage)%"
  }

  private var comparisonPriceLine: String? {
    guard let comparisonPackage else { return nil }
    return annualizedPriceString(for: comparisonPackage).map { "\($0)\(periodSuffix)" }
  }

  private var trialLine: String? {
    guard package.packageType == .annual, let trialText else { return nil }
    return String(localized: "First \(trialText)")
  }

  private var footer: String {
    switch package.packageType {
    case .annual: return String(localized: "Best for building consistency")
    case .weekly: return String(localized: "Flexible access")
    case .monthly: return String(localized: "Simple monthly plan")
    default: return String(localized: "Unlock every Pro tool")
    }
  }

  private var discountPercentage: Int? {
    guard
      let comparisonPackage,
      let annualizedComparisonPrice = annualizedPrice(for: comparisonPackage)
    else { return nil }

    let annualPrice = NSDecimalNumber(decimal: package.storeProduct.price)
    guard annualizedComparisonPrice.compare(annualPrice) == .orderedDescending else { return nil }

    let savings = annualizedComparisonPrice.subtracting(annualPrice)
    let discount = savings.dividing(by: annualizedComparisonPrice).multiplying(by: 100)
    return discount.rounding(accordingToBehavior: PaywallPlanCard.discountRoundingBehavior).intValue
  }

  private func annualizedPrice(for package: Package) -> NSDecimalNumber? {
    let price = NSDecimalNumber(decimal: package.storeProduct.price)

    switch package.packageType {
    case .annual:
      return price
    case .monthly:
      return price.multiplying(by: 12)
    case .weekly:
      return price.multiplying(by: 52)
    default:
      return nil
    }
  }

  private func annualizedPriceString(for package: Package) -> String? {
    guard let price = annualizedPrice(for: package) else { return nil }
    return package.storeProduct.priceFormatter?.string(from: price)
  }

  private static let discountRoundingBehavior = NSDecimalNumberHandler(
    roundingMode: .plain,
    scale: 0,
    raiseOnExactness: false,
    raiseOnOverflow: false,
    raiseOnUnderflow: false,
    raiseOnDivideByZero: false
  )
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
