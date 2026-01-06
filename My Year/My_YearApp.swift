//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import SharedModels
import SwiftDate
import SwiftUI
import SwiftfulRouting

@main
// swiftlint:disable:next type_name
struct My_YearApp: App {
  // * Onboarding Manager
  @StateObject private var onboarding = OnboardingManager()
  @StateObject private var whatsNewManager = WhatsNewManager()
  @StateObject private var featureRequest = FeatureRequestManager(
    appID: "jd76a32gr7hqyp30trwnds7c5x7rfdxq")

  #if DEBUG
    public static let isDebugMode = true
  #else
    public static let isDebugMode = false
  #endif

  init() {
    Purchases.configure(withAPIKey: "appl_rQKHOkYUqJKaipHpcSXlIpPgvPe")

    // * Reviews Promt Manager
    print("start review prompter")
    ReviewPrompter.shared.rules = .init(
      minEvents: 3,
      cooldownDays: 30,
      oncePerVersion: true
    )

    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()


    // Large title → SF monospaced
    appearance.largeTitleTextAttributes = [
      .font: UIFont.monospacedSystemFont(ofSize: 34, weight: .heavy),
      .foregroundColor: UIColor.label
    ]

    // Inline title → SF monospaced
    appearance.titleTextAttributes = [
      .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold),
      .foregroundColor: UIColor.label
    ]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
  }

  static let cachedDates: [Date] = getYearDatesArray()

  var body: some Scene {
    WindowGroup {
      RouterView(addNavigationStack: false, addModuleSupport: true) { _ in
        ContentView()
          .tint(.textSecondary)
      }
      .environment(\.dates, Self.cachedDates)
      .onOpenURL { url in
        if url.scheme == "my-year" && url.host == "clear" {
          let store = ValuationStore.shared
          store.clearAllValuations()
        }
      }
      .environmentObject(onboarding)
      .environmentObject(whatsNewManager)
      .environmentObject(featureRequest)
      .fullScreenCover(isPresented: .constant(!onboarding.hasSeenOnboarding)) {
        OnboardingView {
          onboarding.markAsSeen()
        }
      }
    }
  }
}

struct DatesKey: EnvironmentKey {
  static let defaultValue: [Date] = []
}
extension EnvironmentValues {
  var dates: [Date] {
    get { self[DatesKey.self] }
    set { self[DatesKey.self] = newValue }
  }
}
