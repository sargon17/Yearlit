import RevenueCat
import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = false  // Default to enabled
  @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false  // Add new debug setting
  @AppStorage("wandFillForce") var wandFillForce: Double = 0.5  // Default wand fill force
  @State private var customerInfo: CustomerInfo?
  @EnvironmentObject private var whatsNewManager: WhatsNewManager

  var body: some View {
    VStack(spacing: 0) {
      Form {
        SubscriptionStatusSection(customerInfo: customerInfo)
        About()
        Section(header: Text("Features")) {
          Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
          #if DEBUG
            Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled)  // Add conditional debug toggle
            if runtimeDebugEnabled {
              VStack(alignment: .leading) {
                Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
                Slider(value: $wandFillForce, in: 0.0...1.0, step: 0.05)
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
}

#Preview {
  SettingsView()
}
