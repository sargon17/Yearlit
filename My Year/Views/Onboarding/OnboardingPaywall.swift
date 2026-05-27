import RevenueCat
import SwiftUI

struct OnboardingPaywall: View {
  let showsCloseButton: Bool
  let onNext: () -> Void

  @State private var packages: [Package] = []
  @State private var selectedPackageID: String?
  @State private var isLoading = true
  @State private var isPurchasing = false
  @State private var errorMessage: String?
  @EnvironmentObject private var onboarding: OnboardingManager

  private let heroTopSpacing: CGFloat = 86

  private var selectedPackage: Package? {
    packages.first { $0.identifier == selectedPackageID } ?? preferredPackage(in: packages)
  }

  init(showsCloseButton: Bool = true, onNext: @escaping () -> Void) {
    self.showsCloseButton = showsCloseButton
    self.onNext = onNext
  }

  var body: some View {
    OnboardingStepContainer(overlayHeight: 0.9) {
      GeometryReader { proxy in
        ScrollView {
          PaywallHeroContent()
            .padding(.top, proxy.safeAreaInsets.top + heroTopSpacing)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollIndicators(.hidden)
      }
    } content: {
    } actions: {
      VStack {
        if isLoading {
          PaywallLoadingCard()
        } else if packages.isEmpty {
          PaywallEmptyCard(message: errorMessage ?? String(localized: "Plans are unavailable right now."))
        } else {
          VStack(spacing: 8) {
            ForEach(packages, id: \.identifier) { package in
              PaywallPlanCard(
                package: package,
                isSelected: selectedPackage?.identifier == package.identifier,
                onTap: { selectedPackageID = package.identifier }
              )
            }
          }
        }

        if let errorMessage, !packages.isEmpty {
          Text(errorMessage)
            .font(AppFont.sans(12))
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Button {
          purchaseSelectedPackage()
        } label: {
          HStack(spacing: 8) {
            if isPurchasing {
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
        .disabled(selectedPackage == nil || isPurchasing || isLoading)
        .opacity(selectedPackage == nil || isLoading ? 0.55 : 1)
        .sameLevelBorder(radius: 4, color: .brand)

        PaywallFooterLinks(onRestore: restorePurchases)
      }
      .padding(.top, 4)
    }
    .overlay(alignment: .topTrailing) {
      closeButtonOverlay
    }
    .task {
      await loadPackages()
    }
    .onAppear {
      Analytics.shared.trackPaywallViewed(trigger: .onboarding)
    }
  }

  @ViewBuilder
  private var closeButtonOverlay: some View {
    if showsCloseButton {
      Button(action: finishOnboarding) {
        Image(systemName: "xmark")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.textSecondary)
          .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .modifier(PaywallCloseButtonSurface())
      .padding(.top, 48)
      .padding(.trailing, 12)
      .accessibilityLabel("Close paywall")
    }
  }

  private var primaryButtonTitle: String {
    guard let selectedPackage else { return String(localized: "Continue") }
    return hasFreeTrial(selectedPackage) ? String(localized: "Start Free Trial") : String(localized: "Continue with Pro")
  }

  @MainActor
  private func loadPackages() async {
    isLoading = true
    errorMessage = nil

    do {
      let offerings = try await loadOfferings()
      let offeringPackages = offerings.current?.availablePackages ?? []
      packages = sortedPackages(offeringPackages)
      selectedPackageID = preferredPackage(in: packages)?.identifier
    } catch {
      errorMessage = String(localized: "Couldn’t load plans. Check your connection and try again.")
      packages = []
    }

    isLoading = false
  }

  private func purchaseSelectedPackage() {
    guard let selectedPackage, !isPurchasing else { return }

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil

      do {
        let result = try await Purchases.shared.purchase(package: selectedPackage)
        AnalyticsState.shared.updatePremiumStatus(customerInfo: result.customerInfo)

        if !result.userCancelled {
          finishOnboarding()
        }
      } catch {
        errorMessage = String(localized: "Purchase failed. Please try again.")
      }

      isPurchasing = false
    }
  }

  private func restorePurchases() {
    guard !isPurchasing else { return }

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil

      do {
        let customerInfo = try await Purchases.shared.restorePurchases()
        AnalyticsState.shared.updatePremiumStatus(customerInfo: customerInfo)

        if isPremium(customerInfo: customerInfo) {
          finishOnboarding()
        } else {
          errorMessage = String(localized: "No active subscription found.")
        }
      } catch {
        errorMessage = String(localized: "Restore failed. Please try again.")
      }

      isPurchasing = false
    }
  }

  private func preferredPackage(in packages: [Package]) -> Package? {
    packages.first { $0.packageType == .annual } ?? packages.first
  }

  private func sortedPackages(_ packages: [Package]) -> [Package] {
    packages.sorted { lhs, rhs in
      packageSortRank(lhs) < packageSortRank(rhs)
    }
  }

  private func packageSortRank(_ package: Package) -> Int {
    switch package.packageType {
    case .annual: return 0
    case .weekly: return 1
    case .monthly: return 2
    default: return 10
    }
  }

  private func hasFreeTrial(_ package: Package) -> Bool {
    package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial
  }

  private func finishOnboarding() {
    onboarding.markAsSeen()
    onNext()
  }

  private func loadOfferings() async throws -> Offerings {
    try await withCheckedThrowingContinuation { continuation in
      Purchases.shared.getOfferings { offerings, error in
        if let offerings {
          continuation.resume(returning: offerings)
        } else if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(throwing: PaywallError.missingOfferings)
        }
      }
    }
  }
}

enum PaywallError: Error {
  case missingOfferings
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

      VStack(alignment: .leading, spacing: 4) {
        OnboardingView.Caption("Keep your habits visible with widgets, unlimited")
        OnboardingView.Caption("tracking, and tools built for consistency.")
      }

      VStack(alignment: .leading, spacing: 22) {
        PaywallFeatureRow(title: "Deeper stats", subtitle: "see patterns over time")
        PaywallFeatureRow(title: "Unlimited habits", subtitle: "track every promise")
        PaywallFeatureRow(title: "Widgets", subtitle: "keep your dots on your Home Screen")
        PaywallFeatureRow(title: "Support a solo-built app", subtitle: "Your upgrade helps me keep building Yearlit.")
      }
      .padding(.top, 34)
    }
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

      Text(subtitle)
        .font(AppFont.sans(18))
        .foregroundStyle(.textSecondary.opacity(0.5))
    }
  }
}

private struct PaywallPlanCard: View {
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

private struct PaywallLoadingCard: View {
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

private struct PaywallEmptyCard: View {
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

private struct PaywallFooterLinks: View {
  let onRestore: () -> Void

  var body: some View {
    HStack(spacing: 18) {
      Button("Restore purchases", action: onRestore)
      Link("Terms", destination: URL(string: "https://tymofyeyev.com/yearlit/terms")!)
      Link("Privacy", destination: URL(string: "https://tymofyeyev.com/yearlit/privacy-policy")!)
    }
    .font(AppFont.sans(12))
    .foregroundStyle(.textSecondary)
    .lineLimit(1)
    .minimumScaleFactor(0.75)
    .frame(maxWidth: .infinity)
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
