//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

@main
struct My_YearApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // * Onboarding Manager
  @StateObject private var onboarding = OnboardingManager()
  @StateObject private var featureRequest = FeatureRequestManager(
    config: AppConfig.wishConfiguration
  )
  @StateObject private var reviewPrompter = ReviewPrompter.shared
  @StateObject private var upgradePrompter = UpgradePrompter.shared
  @Environment(\.scenePhase) private var scenePhase
  @State private var isTimelinePreferenceSheetPresented = false
  @State private var hasTrackedOnboardingStarted = false

  #if DEBUG
    static let isDebugMode = true
  #else
    static let isDebugMode = false
  #endif

  init() {
    AppFont.registerFonts()
    if let revenueCatAPIKey = AppConfig.revenueCatAPIKey {
      RevenueCatClient.configure(apiKey: revenueCatAPIKey)
    } else {
      NSLog("RevenueCat is disabled because REVENUECAT_API_KEY is missing.")
    }
    AppStorageMigration.run()
    Analytics.shared.configure()
    configureAcquisitionAttribution()
    Analytics.shared.flushQueuedWidgetEvents()
    if RevenueCatClient.isConfigured {
      Purchases.shared.getCustomerInfo { info, _ in
        Task { @MainActor in
          AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
        }
      }
    }

    ReviewPrompter.shared.rules = .init(
      minEvents: 3,
      cooldownDays: 30,
      oncePerVersion: false
    )
    UpgradePrompter.shared.rules = .init(
      minPositiveEvents: 2,
      cooldownDays: 7,
      minDaysSinceInstallForTimedPrompt: 3,
      timedPromptChance: 0.08
    )

    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()

    appearance.largeTitleTextAttributes = [
      .font: AppFont.uiFont(.pixelCircle, size: 56),
      .foregroundColor: UIColor.label
    ]

    appearance.titleTextAttributes = [
      .font: AppFont.uiFont(.mono, size: 18),
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
        guard url.scheme == "my-year" else { return }

        switch url.host {
        case "calendar":
          handleWidgetOpenURL(url)
        case "quick-add":
          handleWidgetQuickAddURL(url)
        default:
          handleWidgetOpenURL(url)
        }
      }
      .environmentObject(onboarding)
      .environmentObject(featureRequest)
      .environmentObject(reviewPrompter)
      .environmentObject(upgradePrompter)
      .fullScreenCover(
        isPresented: onboardingPresentation,
        onDismiss: {
          updateTimelinePreferencePresentation()
        },
        content: {
          OnboardingView {
            completeOnboarding()
          }
        }
      )
      .fullScreenCover(isPresented: $isTimelinePreferenceSheetPresented) {
        TimelinePreferenceChoiceSheet { mode in
          TimelinePreferenceManager.shared.setMode(mode)
          isTimelinePreferenceSheetPresented = false
        }
      }
      .sheet(item: $reviewPrompter.activePrompt) { context in
        ReviewSatisfactionSheet(prompter: reviewPrompter, context: context)
          .environmentObject(featureRequest)
      }
      .sheet(item: $upgradePrompter.activePrompt) { context in
        PremiumPaywallSheet(
          displayCloseButton: true,
          trigger: context.trigger,
          analyticsProperties: context.analyticsProperties
        )
      }
      .onAppear {
        #if DEBUG
          DebugSwipeCalendarSeeder.seedIfRequested(onboarding: onboarding)
        #endif
        updateTimelinePreferencePresentation()
        trackOnboardingStartedIfNeeded()
      }
      .onChange(of: onboarding.hasSeenOnboarding) { _, hasSeenOnboarding in
        if hasSeenOnboarding {
          updateTimelinePreferencePresentation()
        } else {
          trackOnboardingStartedIfNeeded()
        }
      }
      .onChange(of: scenePhase) { _, phase in
        guard phase == .active else { return }
        Analytics.shared.flushQueuedWidgetEvents()
        Analytics.shared.track(.appOpened)
        if onboarding.hasSeenOnboarding, reviewPrompter.activePrompt == nil {
          upgradePrompter.considerTimedPrompt()
        }
      }
    }
  }

  private var onboardingPresentation: Binding<Bool> {
    Binding(
      get: { !onboarding.hasSeenOnboarding },
      set: { isPresented in
        guard !isPresented else { return }
        completeOnboarding()
      }
    )
  }

  private func completeOnboarding() {
    let isNewUser = !onboarding.hasSeenOnboarding
    if isNewUser {
      TimelinePreferenceStore.setDefaultModeIfNeeded()
      TimelinePreferenceManager.shared.refresh()
    }

    onboarding.markAsSeen()
  }

  private func configureAcquisitionAttribution() {
    guard RevenueCatClient.isConfigured else { return }

    let revenueCatAppUserID = Purchases.shared.appUserID
    let postHogDistinctID = AnalyticsState.shared.distinctID

    AnalyticsState.shared.updateRevenueCatAppUserID(revenueCatAppUserID)
    AnalyticsState.shared.markAppleAdsAdServicesEnabled()
    Purchases.shared.attribution.setAttributes([
      "posthog_distinct_id": postHogDistinctID,
      "revenuecat_app_user_id": revenueCatAppUserID
    ])
    Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
    Analytics.shared.updatePersonProperties()
  }

  private func updateTimelinePreferencePresentation() {
    isTimelinePreferenceSheetPresented =
      onboarding.hasSeenOnboarding && !TimelinePreferenceStore.hasStoredMode()
  }

  private func trackOnboardingStartedIfNeeded() {
    guard !onboarding.hasSeenOnboarding, !hasTrackedOnboardingStarted else { return }
    hasTrackedOnboardingStarted = true
    Analytics.shared.track(.onboardingStarted)
  }
}
