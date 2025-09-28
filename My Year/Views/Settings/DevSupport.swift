import RevenueCat
import RevenueCatUI
import StoreKit
import SwiftUI
import SwiftfulRouting
import UIKit

struct DevSupport: View {
  @Environment(\.router) var router

  @State private var customerInfo: CustomerInfo?

  func isPremium() -> Bool {
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
          router.showScreen(.sheet) { AnyRouter in
            PaywallView()
          }
        } label: {
          Label("Get PRO", systemImage: "star")
        }
      }
    }
  }
}
