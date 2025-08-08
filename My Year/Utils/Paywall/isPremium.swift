import RevenueCat

func isPremium(
  customerInfo: CustomerInfo?
) -> Bool {
  return customerInfo?.entitlements["premium"]?.isActive ?? false
}
