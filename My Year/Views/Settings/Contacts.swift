import SwiftfulRouting
import SwiftUI

struct Contacts: View {
    @Environment(\.router) private var router
    @EnvironmentObject private var featureRequestManager: FeatureRequestManager

    var body: some View {
        Section(header: Text("Contacts")) {
            VStack(alignment: .leading, spacing: 4) {
                Text("See something off? Have an idea?")
                    .foregroundStyle(.textPrimary)
                Text(
                    "Don’t keep it to yourself. The fastest way to make this app better for you is to tell me what’s on your mind."
                )
            }
            .font(AppFont.mono(11))
            .foregroundColor(.secondary)
            Button {
                if let url = URL(string: "mailto:mykhaylo.tymofyeyev@gmail.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Mail the Developer", systemImage: "envelope")
            }
            Button {
                if let url = URL(string: "https://t.me/Mykhaylo17") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Message on Telegram", systemImage: "paperplane")
            }
            if featureRequestManager.isConfigured {
                Button {
                    router.showScreen(.push) { _ in
                        FeatureRequestsList()
                    }
                } label: {
                    Label("Request a Feature", systemImage: "flask")
                }
            }
        }
    }
}

// See something off? Have an idea?
// Don’t keep it to yourself.
// The fastest way to make this app better for you is to tell me what’s on your mind.
