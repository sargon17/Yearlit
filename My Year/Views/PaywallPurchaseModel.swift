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

  var selectedPackage: Package? {
    packages.first { $0.identifier == selectedPackageID } ?? preferredPackage(in: packages)
  }

  var primaryButtonTitle: String {
    guard let selectedPackage else { return String(localized: "Continue") }
    return hasFreeTrial(selectedPackage)
      ? String(localized: "Start Free Trial")
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

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil

      do {
        let result = try await Purchases.shared.purchase(package: selectedPackage)
        AnalyticsState.shared.updatePremiumStatus(customerInfo: result.customerInfo)

        if !result.userCancelled {
          onSuccess()
        }
      } catch {
        errorMessage = String(localized: "Purchase failed. Please try again.")
      }

      isPurchasing = false
    }
  }

  func restorePurchases(onActiveSubscription: @escaping () -> Void) {
    guard !isPurchasing else { return }

    Task { @MainActor in
      isPurchasing = true
      errorMessage = nil

      do {
        let customerInfo = try await Purchases.shared.restorePurchases()
        AnalyticsState.shared.updatePremiumStatus(customerInfo: customerInfo)

        if isPremium(customerInfo: customerInfo) {
          onActiveSubscription()
        } else {
          errorMessage = String(localized: "No active subscription found.")
        }
      } catch {
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
}
