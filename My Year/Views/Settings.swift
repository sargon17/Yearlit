import RevenueCat
import SwiftUI

struct SettingsView: View {
  @State private var customerInfo: CustomerInfo?
  @EnvironmentObject private var whatsNewManager: WhatsNewManager

  var body: some View {
    VStack(spacing: 0) {
      Form {
        SubscriptionStatusSection(customerInfo: customerInfo)

        About()

        PoliciesSection()

        Features()

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
