import SwiftUI

struct PoliciesSection: View {
    struct PolicyLink {
        var lanel: String
        var url: URL
    }

    private var policies: [PolicyLink] {
        [
            PolicyLink(lanel: "Privacy Policy", url: URL(string: "https://tymofyeyev.com/yearlit/privacy-policy")!),
            PolicyLink(lanel: "Terms of Service", url: URL(string: "https://tymofyeyev.com/yearlit/terms")!),
            PolicyLink(lanel: "EULA", url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!),
        ]
    }

    var body: some View {
        Section(header: Text("Policies")) {
            ForEach(policies, id: \.lanel) { policy in
                Link(policy.lanel, destination: policy.url)
            }
        }
    }
}

#Preview {
    PoliciesSection()
}
