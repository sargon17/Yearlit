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
import UserNotifications

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self

    // Setup notification categories
    setupNotificationCategories()

    return true
  }

  /// Handle notification actions (Log Now, Snooze, and default tap)
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Handle default tap action (user tapped notification) - open calendar
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let userInfo = response.notification.request.content.userInfo
      if let calendarIdString = userInfo["calendarId"] as? String,
        let calendarId = UUID(uuidString: calendarIdString)
      {
        // Open deep link to calendar
        let deepLinkURL = URL(string: "my-year://calendar/\(calendarId.uuidString)")!
        UIApplication.shared.open(deepLinkURL)
        print("📱 Opening calendar from notification: \(calendarIdString)")
      }
    } else {
      // Handle action buttons (Log Now, Snooze)
      Task { @MainActor in
        handleNotificationAction(response, store: CustomCalendarStore.shared)
      }
    }

    completionHandler()
  }

  /// Handle notification when app is in foreground
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    Task { @MainActor in
      let userInfo = notification.request.content.userInfo
      let snapshot = CustomCalendarStore.shared.snapshot
      if let calendarIdString = userInfo["calendarId"] as? String,
        let calendarId = UUID(uuidString: calendarIdString),
        let calendar = snapshot.calendar(id: calendarId),
        calendar.suppressWhenCompleted,
        shouldSuppressNotification(for: calendar, store: CustomCalendarStore.shared)
      {
        print("🔕 Suppressed notification for \(calendar.name) - already completed today")
        completionHandler([])
        return
      }

      completionHandler([.banner, .sound, .badge])
    }
  }
}

@main
// swiftlint:disable:next type_name
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
  @State private var isDataRecoveryPresented = false
  @State private var hasTrackedOnboardingStarted = false

  #if DEBUG
    static let isDebugMode = true
  #else
    static let isDebugMode = false
  #endif

  init() {
    AppFont.registerFonts()
    Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
    AppStorageMigration.run()
    Analytics.shared.configure()
    configureAcquisitionAttribution()
    Analytics.shared.flushQueuedWidgetEvents()
    Purchases.shared.getCustomerInfo { info, _ in
      Task { @MainActor in
        AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
      }
    }

    // * Reviews Promt Manager
    print("start review prompter")
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

    // Large title → Geist Pixel Circle
    appearance.largeTitleTextAttributes = [
      .font: AppFont.uiFont(.pixelCircle, size: 56),
      .foregroundColor: UIColor.label
    ]

    // Inline title → Geist Pixel Circle
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
        case "clear":
          let store = ValuationStore.shared
          store.clearAllValuations()
        case "calendar":
          handleWidgetOpenURL(url)
        case "quick-add":
          handleWidgetQuickAddURL(url)
        case "data-recovery":
          isDataRecoveryPresented = true
        default:
          handleWidgetOpenURL(url)
          break
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
        }
      ) {
        OnboardingView {
          completeOnboarding()
        }
      }
      .fullScreenCover(isPresented: $isTimelinePreferenceSheetPresented) {
        TimelinePreferenceChoiceSheet { mode in
          TimelinePreferenceManager.shared.setMode(mode)
          isTimelinePreferenceSheetPresented = false
        }
      }
      .sheet(isPresented: $isDataRecoveryPresented) {
        NavigationStack {
          DataRecoveryView()
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
    let revenueCatAppUserID = Purchases.shared.appUserID
    let postHogDistinctID = AnalyticsState.shared.distinctID

    AnalyticsState.shared.updateRevenueCatAppUserID(revenueCatAppUserID)
    AnalyticsState.shared.markAppleAdsAdServicesEnabled()
    Purchases.shared.attribution.setAttributes([
      "$posthogUserId": postHogDistinctID,
      "posthog_distinct_id": postHogDistinctID,
      "revenuecat_app_user_id": revenueCatAppUserID
    ])
    Purchases.shared.syncAttributesAndOfferingsIfNeeded { _, _ in }
    Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
    Analytics.shared.updatePersonProperties()
  }

  private func updateTimelinePreferencePresentation() {
    isTimelinePreferenceSheetPresented = onboarding.hasSeenOnboarding && !TimelinePreferenceStore.hasStoredMode()
  }

  private func trackOnboardingStartedIfNeeded() {
    guard !onboarding.hasSeenOnboarding, !hasTrackedOnboardingStarted else { return }
    hasTrackedOnboardingStarted = true
    Analytics.shared.track(
      .onboardingStarted,
      properties: [
        "onboarding_flow": .string(OnboardingCopy.flowID)
      ]
    )
  }
}

@MainActor
private func handleWidgetOpenURL(_ url: URL) {
  guard let widgetContext = WidgetDeepLinkAnalytics.context(from: url) else { return }

  Analytics.shared.track(
    .widgetOpenedApp,
    properties: [
      "widget_kind": .string(widgetContext.widgetKind),
      "widget_action": .string(widgetContext.widgetAction),
      "destination": .string(widgetContext.destination)
    ]
  )
  Analytics.shared.flushQueuedWidgetEvents()
}

@MainActor
func handleWidgetQuickAddURL(_ url: URL) {
  let widgetContext = WidgetDeepLinkAnalytics.context(from: url)
  if let widgetContext {
    Analytics.shared.track(
      .widgetQuickAddOpened,
      properties: [
        "widget_kind": .string(widgetContext.widgetKind),
        "widget_action": .string(widgetContext.widgetAction),
        "destination": .string(widgetContext.destination)
      ]
    )
    Analytics.shared.track(
      .widgetOpenedApp,
      properties: [
        "widget_kind": .string(widgetContext.widgetKind),
        "widget_action": .string(widgetContext.widgetAction),
        "destination": .string(widgetContext.destination)
      ]
    )
    Analytics.shared.flushQueuedWidgetEvents()
  }

  let idString = url.pathComponents.dropFirst().first
  guard let idString, let calendarId = UUID(uuidString: idString) else { return }

  let store = CustomCalendarStore.shared
  let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
  guard let calendar = calendars.first(where: { $0.id == calendarId }) else { return }

  quickEntry(
    calendar: calendar,
    date: Date(),
    calendarStore: store,
    source: .quickAddDeeplink
  )
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
