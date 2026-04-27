import Foundation
import RevenueCat

@MainActor
final class EntitlementManager: NSObject, ObservableObject, PurchasesDelegate {
  @Published private(set) var customerInfo: CustomerInfo?
  @Published private(set) var isPremium = false
  @Published private(set) var lastRefreshError: Error?

  private var isStarted = false

  func start() {
    guard !isStarted else { return }
    isStarted = true
    Purchases.shared.delegate = self
  }

  func refresh() async {
    start()

    do {
      apply(try await Purchases.shared.customerInfo())
      lastRefreshError = nil
    } catch {
      lastRefreshError = error
      NSLog("Failed to refresh RevenueCat customer info: \(error)")
    }
  }

  nonisolated func purchases(_: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    Task { @MainActor in
      self.apply(customerInfo)
    }
  }

  private func apply(_ info: CustomerInfo) {
    customerInfo = info
    isPremium = info.entitlements["premium"]?.isActive == true
  }
}
