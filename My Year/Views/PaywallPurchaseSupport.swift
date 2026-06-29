import Foundation
import RevenueCat

func preferredPackage(in packages: [Package]) -> Package? {
  packages.first { $0.packageType == .annual } ?? packages.first
}

func sortedPackages(_ packages: [Package]) -> [Package] {
  packages.sorted { lhs, rhs in
    packageSortRank(lhs) < packageSortRank(rhs)
  }
}

func packageSortRank(_ package: Package) -> Int {
  switch package.packageType {
  case .annual: return 0
  case .weekly: return 1
  case .monthly: return 2
  default: return 10
  }
}

func hasFreeTrial(_ package: Package) -> Bool {
  package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial
}

func purchaseErrorCategory(_ error: Error) -> PaywallErrorCategory {
  networkErrorCategory(error) ?? .purchaseFailed
}

func isPurchaseCancelled(_ error: Error) -> Bool {
  ErrorCode(_bridgedNSError: error as NSError) == .purchaseCancelledError
}

func restoreErrorCategory(_ error: Error) -> PaywallErrorCategory {
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

extension Package {
  var paywallAnalyticsContext: PaywallPackageAnalyticsContext {
    PaywallPackageAnalyticsContext(
      identifier: identifier,
      type: paywallAnalyticsPackageType,
      hasFreeTrial: hasFreeTrial(self),
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
