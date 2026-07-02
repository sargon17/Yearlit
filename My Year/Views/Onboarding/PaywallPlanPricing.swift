import RevenueCat
import SwiftUI

extension PaywallPlanCard {
  var isFeatured: Bool {
    package.packageType == .annual
  }

  var title: String {
    switch package.packageType {
    case .annual: return String(localized: "Yearly")
    case .weekly: return String(localized: "Weekly")
    case .monthly: return String(localized: "Monthly")
    default: return package.storeProduct.localizedTitle.nilIfEmpty ?? String(localized: "Pro")
    }
  }

  var priceLine: String {
    if let trialText {
      return String(localized: "\(trialText), then \(package.localizedPriceString)\(periodSuffix)")
    }

    return "\(package.localizedPriceString)\(periodSuffix)"
  }

  var currentPriceLine: String {
    "\(package.localizedPriceString)\(periodSuffix)"
  }

  var periodSuffix: String {
    switch package.packageType {
    case .annual: return String(localized: "/year")
    case .weekly: return String(localized: "/week")
    case .monthly: return String(localized: "/month")
    default: return ""
    }
  }

  var trialText: String? {
    guard
      let intro = package.storeProduct.introductoryDiscount,
      intro.paymentMode == .freeTrial
    else { return nil }

    let value = intro.subscriptionPeriod.value * intro.numberOfPeriods
    let unit = intro.subscriptionPeriod.unit.paywallUnitName(for: value)
    return String(localized: "\(value) \(unit) free")
  }

  var badge: String? {
    guard let discountPercentage else { return nil }
    return "-\(discountPercentage)%"
  }

  var comparisonPriceLine: String? {
    guard let comparisonPackage else { return nil }
    return annualizedPriceString(for: comparisonPackage).map { "\($0)\(periodSuffix)" }
  }

  var trialLine: String? {
    guard package.packageType == .annual, let trialText else { return nil }
    return String(localized: "First \(trialText)")
  }

  var footer: String {
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
    return discount.rounding(accordingToBehavior: Self.discountRoundingBehavior).intValue
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

private extension SubscriptionPeriod.Unit {
  func paywallUnitName(for value: Int) -> String {
    switch self {
    case .day: return value == 1 ? String(localized: "day") : String(localized: "days")
    case .week: return value == 1 ? String(localized: "week") : String(localized: "weeks")
    case .month: return value == 1 ? String(localized: "month") : String(localized: "months")
    case .year: return value == 1 ? String(localized: "year") : String(localized: "years")
    @unknown default: return String(localized: "days")
    }
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
