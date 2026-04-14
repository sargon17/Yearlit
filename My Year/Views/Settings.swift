import RevenueCat
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false // Default to disabled
    @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false // Default to disabled
    @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false // Add new debug setting
    @AppStorage("wandFillForce") var wandFillForce: Double = 0.5 // Default wand fill force
    @State private var customerInfo: CustomerInfo?
    @EnvironmentObject private var whatsNewManager: WhatsNewManager

    var body: some View {
        VStack(spacing: 0) {
            Form {
                SubscriptionStatusSection(customerInfo: customerInfo)
                About()
                Section(header: Text("Policies")) {
                    if let url = privacyPolicyURL {
                        Link("Privacy Policy", destination: url)
                    }
                    if let url = termsURL {
                        Link("Terms", destination: url)
                    }
                }
                Section(header: Text("Features")) {
                    Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
                    Toggle("Enable Recap View", isOn: $isRecapViewEnabled)
                    #if DEBUG
                        Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled) // Add conditional debug toggle
                        if runtimeDebugEnabled {
                            VStack(alignment: .leading) {
                                Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
                                Slider(value: $wandFillForce, in: 0.0 ... 1.0, step: 0.05)
                            }
                            Button("Reset What's New") {
                                whatsNewManager.resetLastSeenVersion()
                            }
                        }
                    #endif
                }
                Contacts()
                DevSupportSection(customerInfo: customerInfo)
                DevCredits()
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            .scrollContentBackground(.hidden)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("text-secondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
        .navigationTitle("Settings")
        .onAppear {
            Purchases.shared.getCustomerInfo { info, _ in
                customerInfo = info
            }
        }
    }

    private var privacyPolicyURL: URL? {
        guard let url = URL(string: "https://tymofyeyev.com/yearlit/privacy-policy") else {
            return nil
        }
        return url
    }

    private var termsURL: URL? {
        guard let url = URL(string: "https://tymofyeyev.com/yearlit/terms") else {
            return nil
        }
        return url
    }
}

#Preview {
    SettingsView()
}
