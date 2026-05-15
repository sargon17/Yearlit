import RevenueCat
import RevenueCatUI
import StoreKit
import SwiftfulRouting
import SwiftUI
import UIKit

struct SubscriptionStatusSection: View {
    let customerInfo: CustomerInfo?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let lifetimeThresholdYear = 2099
    private let lifetimeProductIdentifier = "Lp4wMNtHVWHCf7L3KqaH"
    private let appUserId = Purchases.shared.appUserID

    var body: some View {
        if let entitlement = customerInfo?.entitlements["premium"], entitlement.isActive {
            Section(header: Text("Subscription")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("You are on PRO.")
                        .font(AppFont.mono(13, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Thanks for supporting Yearlit.")
                        .font(AppFont.mono(12))
                        .foregroundColor(.textSecondary)

                    if let expirationDate = entitlement.expirationDate {
                        if isLifetime(entitlement: entitlement, expirationDate: expirationDate) {
                            Text("Renews: lifetime")
                                .font(AppFont.mono(12))
                                .foregroundColor(.textSecondary)
                        } else {
                            Text("Renews: \(dateFormatter.string(from: expirationDate))")
                                .font(AppFont.mono(12))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text("Renews: lifetime")
                            .font(AppFont.mono(12))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.vertical, 6)

                Button {
                    UIPasteboard.general.string = appUserId
                } label: {
                    Label("Copy App User ID", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private func isLifetime(entitlement: EntitlementInfo, expirationDate: Date) -> Bool {
        if entitlement.productIdentifier == lifetimeProductIdentifier {
            return true
        }
        let year = Calendar.current.component(.year, from: expirationDate)
        return year >= lifetimeThresholdYear
    }
}

struct DevSupportSection: View {
    @Environment(\.router) var router
    let customerInfo: CustomerInfo?

    private func isPremium() -> Bool {
        return customerInfo?.entitlements["premium"]?.isActive ?? false
    }

    var body: some View {
        Section(header: Text("Support the Developer")) {
            Button {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    if #available(iOS 18.0, *) {
                        AppStore.requestReview(in: scene)
                    } else {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            } label: {
                Label("Leave a Review", systemImage: "bubble.and.pencil")
            }
            if !isPremium() {
                Button {
                    router.showScreen(.sheet) { _ in
                        PaywallView()
                    }
                } label: {
                    Label("Get PRO", systemImage: "star")
                }
            }
        }
    }
}
