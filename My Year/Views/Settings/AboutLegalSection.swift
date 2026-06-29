import SwiftUI
import SwiftfulRouting

struct AboutLegalSection: View {
  @Environment(\.router) var router

  private struct PolicyLink {
    let label: String
    let urlString: String
  }

  private let policies = [
    PolicyLink(label: "Privacy Policy", urlString: "https://tymofyeyev.com/yearlit/privacy-policy"),
    PolicyLink(label: "Terms of Service", urlString: "https://tymofyeyev.com/yearlit/terms"),
    PolicyLink(label: "EULA", urlString: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
  ]

  var body: some View {
    Section(header: Text("About & Legal")) {
      Button("My Note to You") {
        router.showScreen(.fullScreenCover) { _ in
          AboutThisProject()
        }
      }

      ForEach(policies, id: \.label) { policy in
        if let url = URL(string: policy.urlString) {
          Link(policy.label, destination: url)
        }
      }
    }
  }
}
