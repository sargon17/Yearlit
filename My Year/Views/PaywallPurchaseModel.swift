import RevenueCat
import SwiftUI

private enum PaywallError: Error {
  case missingOfferings
}

@MainActor
final class PaywallPurchaseModel: ObservableObject {
  @Published var packages: [Package] = []
  @Published var selectedPackageID: String?
  @Published var isLoading = true
  @Published var isPurchasing = false
  @Published var errorMessage: String?

  private let trigger: PaywallTrigger
  private let variant: PaywallVariant
  private let analyticsProperties: [String: AnalyticsPropertyValue]

  init(
    trigger: PaywallTrigger,
    variant: PaywallVariant,
    analyticsProperties: [String: AnalyticsPropertyValue] = [:]
  ) {
    self.trigger = trigger
    self.variant = variant
    self.analyticsProperties = analyticsProperties
  }

  var selectedPackage: Package? {
    packages.first { $0.identifier == selectedPackageID } ?? preferredPackage(in: packages)
  }

  var primaryButtonTitle: String {
    guard let selectedPackage else { return String(localized: "Continue") }
    return hasFreeTrial(selectedPackage)
      ? String(localized: "Start for Free")
      : String(localized: "Continue with Pro")
  }

  func loadPackages() async {
    isLoading = true
    errorMessage = nil

    do {
      let offerings = try await loadOfferings()
      packages = sortedPackages(offerings.current?.availablePackages ?? [])
      selectedPackageID = preferredPackage(in: packages)?.identifier
    } catch {
      errorMessage = String(localized: "Couldn’t load plans. Check your connection and try again.")
      packages = []
    }

    isLoading = false
  }

  func purchaseSelectedPackage(onSuccess: @escaping () -> Void) {
    guard let selectedPackage, !isPurchasing else { return }
    let packageContext = selectedPackage.paywallAnalyticsContext

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil
      Analytics.shared.trackPaywallPurchaseStarted(
        trigger: trigger,
        variant: variant,
        package: packageContext,
        properties: analyticsProperties
      )

      do {
        let result = try await Purchases.shared.purchase(package: selectedPackage)
        AnalyticsState.shared.updatePremiumStatus(customerInfo: result.customerInfo)

        if result.userCancelled {
          Analytics.shared.trackPaywallPurchaseCancelled(
            trigger: trigger,
            variant: variant,
            package: packageContext,
            properties: analyticsProperties
          )
        } else {
          Analytics.shared.trackPaywallPurchaseSucceeded(
            trigger: trigger,
            variant: variant,
            package: packageContext,
            properties: analyticsProperties
          )
          onSuccess()
        }
      } catch {
        if isPurchaseCancelled(error) {
          Analytics.shared.trackPaywallPurchaseCancelled(
            trigger: trigger,
            variant: variant,
            package: packageContext,
            properties: analyticsProperties
          )
        } else {
          Analytics.shared.trackPaywallPurchaseFailed(
            trigger: trigger,
            variant: variant,
            package: packageContext,
            errorCategory: purchaseErrorCategory(error),
            properties: analyticsProperties
          )
          errorMessage = String(localized: "Purchase failed. Please try again.")
        }
      }

      isPurchasing = false
    }
  }

  func restorePurchases(onActiveSubscription: @escaping () -> Void) {
    guard !isPurchasing else { return }

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil
      Analytics.shared.trackPaywallRestoreStarted(
        trigger: trigger,
        variant: variant,
        properties: analyticsProperties
      )

      do {
        let customerInfo = try await Purchases.shared.restorePurchases()
        AnalyticsState.shared.updatePremiumStatus(customerInfo: customerInfo)

        if isPremium(customerInfo: customerInfo) {
          Analytics.shared.trackPaywallRestoreSucceeded(
            trigger: trigger,
            variant: variant,
            properties: analyticsProperties
          )
          onActiveSubscription()
        } else {
          Analytics.shared.trackPaywallRestoreFailed(
            trigger: trigger,
            variant: variant,
            errorCategory: .restoreFailed,
            properties: analyticsProperties
          )
          errorMessage = String(localized: "No active subscription found.")
        }
      } catch {
        Analytics.shared.trackPaywallRestoreFailed(
          trigger: trigger,
          variant: variant,
          errorCategory: restoreErrorCategory(error),
          properties: analyticsProperties
        )
        errorMessage = String(localized: "Restore failed. Please try again.")
      }

      isPurchasing = false
    }
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

  private func purchaseErrorCategory(_ error: Error) -> PaywallErrorCategory {
    return networkErrorCategory(error) ?? .purchaseFailed
  }

  private func isPurchaseCancelled(_ error: Error) -> Bool {
    ErrorCode(_bridgedNSError: error as NSError) == .purchaseCancelledError
  }

  private func restoreErrorCategory(_ error: Error) -> PaywallErrorCategory {
    networkErrorCategory(error) ?? .restoreFailed
  }

  private func networkErrorCategory(_ error: Error) -> PaywallErrorCategory? {
    let revenueCatCode = ErrorCode(_bridgedNSError: error as NSError)
    if revenueCatCode == .networkError || revenueCatCode == .offlineConnectionError {
      return .network
    }

    let nsError = error as NSError
    return nsError.domain == NSURLErrorDomain ? .network : nil
  }
}

extension Package {
  var paywallAnalyticsContext: PaywallPackageAnalyticsContext {
    PaywallPackageAnalyticsContext(
      identifier: identifier,
      type: paywallAnalyticsPackageType,
      hasFreeTrial: storeProduct.introductoryDiscount?.paymentMode == .freeTrial,
      localizedPrice: localizedPriceString
    )
  }

  private var paywallAnalyticsPackageType: PaywallPackageType {
    switch packageType {
    case .annual: return .annual
    case .monthly: return .monthly
    case .weekly: return .weekly
    default: return .unknown
    }
  }
}
