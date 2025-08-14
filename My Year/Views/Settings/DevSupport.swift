import StoreKit
import SwiftUI
import UIKit

struct DevSupport: View {
  var body: some View {
    Section(header: Text("Support")) {
      Button("Leave a Review") {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
          if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
          } else {
            SKStoreReviewController.requestReview(in: scene)
          }
        }
      }
    }
  }
}
