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

    guard RevenueCatClient.isConfigured else {
      errorMessage = String(localized: "Purchases are unavailable in this build.")
      packages = []
      isLoading = false
      return
    }

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
    guard RevenueCatClient.isConfigured else {
      errorMessage = String(localized: "Purchases are unavailable in this build.")
      return
    }
    guard let selectedPackage, !isPurchasing else { return }
    let packageContext = selectedPackage.paywallAnalyticsContext

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil
      defer { isPurchasing = false }

      Analytics.shared.trackPaywallPurchaseStarted(
        trigger: trigger,
        variant: variant,
        package: packageContext,
        properties: analyticsProperties
      )

      do {
        let result = try await Purchases.shared.purchase(package: selectedPackage)
        handlePurchaseResult(result, package: packageContext, onSuccess: onSuccess)
      } catch {
        handlePurchaseError(error, package: packageContext)
      }
    }
  }

  func restorePurchases(onActiveSubscription: @escaping () -> Void) {
    guard RevenueCatClient.isConfigured else {
      errorMessage = String(localized: "Purchases are unavailable in this build.")
      return
    }
    guard !isPurchasing else { return }

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil
      defer { isPurchasing = false }

      Analytics.shared.trackPaywallRestoreStarted(
        trigger: trigger,
        variant: variant,
        properties: analyticsProperties
      )

      do {
        let customerInfo = try await Purchases.shared.restorePurchases()
        handleRestoreResult(customerInfo, onActiveSubscription: onActiveSubscription)
      } catch {
        handleRestoreError(error)
      }
    }
  }

  private func handlePurchaseResult(
    _ result: PurchaseResultData,
    package: PaywallPackageAnalyticsContext,
    onSuccess: () -> Void
  ) {
    AnalyticsState.shared.updatePremiumStatus(customerInfo: result.customerInfo)

    if result.userCancelled {
      trackPurchaseCancelled(package: package)
    } else {
      Analytics.shared.trackPaywallPurchaseSucceeded(
        trigger: trigger,
        variant: variant,
        package: package,
        properties: analyticsProperties
      )
      onSuccess()
    }
  }

  private func handlePurchaseError(_ error: Error, package: PaywallPackageAnalyticsContext) {
    if isPurchaseCancelled(error) {
      trackPurchaseCancelled(package: package)
    } else {
      Analytics.shared.trackPaywallPurchaseFailed(
        trigger: trigger,
        variant: variant,
        package: package,
        errorCategory: purchaseErrorCategory(error),
        properties: analyticsProperties
      )
      errorMessage = String(localized: "Purchase failed. Please try again.")
    }
  }

  private func trackPurchaseCancelled(package: PaywallPackageAnalyticsContext) {
    Analytics.shared.trackPaywallPurchaseCancelled(
      trigger: trigger,
      variant: variant,
      package: package,
      properties: analyticsProperties
    )
  }

  private func handleRestoreResult(
    _ customerInfo: CustomerInfo,
    onActiveSubscription: () -> Void
  ) {
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
  }

  private func handleRestoreError(_ error: Error) {
    Analytics.shared.trackPaywallRestoreFailed(
      trigger: trigger,
      variant: variant,
      errorCategory: restoreErrorCategory(error),
      properties: analyticsProperties
    )
    errorMessage = String(localized: "Restore failed. Please try again.")
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
