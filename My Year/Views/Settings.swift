import RevenueCat
import SwiftUI

struct SettingsView: View {
  @State private var customerInfo: CustomerInfo?

  var body: some View {
    VStack(spacing: 0) {
      Form {
        ProSection(customerInfo: customerInfo)

        YearExperienceSection()

        MotivationSection()

        WidgetsSettingsSection()

        DailyWallpaperSettingsSection(customerInfo: customerInfo)

        HelpFeedbackSection()

        SupportYearlitSection()

        DeveloperSettingsSection()

        AboutLegalSection()

        DeveloperFooterView()
      }
      .scrollContentBackground(.hidden)
      .font(AppFont.mono(12))
      .foregroundColor(Color("text-secondary"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Settings")
    .onAppear {
      if RevenueCatClient.isConfigured {
        Purchases.shared.getCustomerInfo { info, _ in
          customerInfo = info
          AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
        }
      }
    }
  }
}

private struct DeveloperFooterView: View {
  @AppStorage(AppStorageKeys.isDeveloperModeEnabled) private var isDeveloperModeEnabled: Bool = false
  @State private var developerModeTapCount: Int = 0

  private func handleIconTap() {
    guard !isDeveloperModeEnabled else { return }

    developerModeTapCount += 1
    if developerModeTapCount >= 10 {
      isDeveloperModeEnabled = true
      developerModeTapCount = 0
      Task {
        await hapticFeedback(.light)
      }
    }
  }

  var body: some View {
    VStack(spacing: 8) {
      Image("icon")
        .resizable()
        .scaledToFit()
        .frame(width: 36, height: 36)
        .onTapGesture {
          handleIconTap()
        }

      DevCredits()
    }
    .padding(.top, 8)
    .frame(maxWidth: .infinity, alignment: .center)
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets())
  }
}

#Preview {
  SettingsView()
}
