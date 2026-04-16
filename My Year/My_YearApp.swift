//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import SharedModels
import SwiftDate
import SwiftfulRouting
import SwiftUI
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
        let store = CustomCalendarStore.shared

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
            handleNotificationAction(response, store: store)
        }

        completionHandler()
    }

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if notification should be suppressed
        let userInfo = notification.request.content.userInfo
        if let calendarIdString = userInfo["calendarId"] as? String,
           let calendarId = UUID(uuidString: calendarIdString),
           let calendar = CustomCalendarStore.shared.calendars.first(where: { $0.id == calendarId }),
           shouldSuppressNotification(for: calendar, store: CustomCalendarStore.shared)
        {
            // Suppress notification - entry already completed
            print("🔕 Suppressed notification for \(calendar.name) - already completed today")
            completionHandler([])
            return
        }

        // Show notification
        completionHandler([.banner, .sound, .badge])
    }
}

@main
// swiftlint:disable:next type_name
struct My_YearApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // * Onboarding Manager
    @StateObject private var onboarding = OnboardingManager()
    @StateObject private var whatsNewManager = WhatsNewManager()
    @StateObject private var featureRequest = FeatureRequestManager(
        appID: "jd76a32gr7hqyp30trwnds7c5x7rfdxq"
    )

    #if DEBUG
        static let isDebugMode = true
    #else
        static let isDebugMode = false
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
            .foregroundColor: UIColor.label,
        ]

        // Inline title → SF monospaced
        appearance.titleTextAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.label,
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
                case "quick-add":
                    let idString = url.pathComponents.dropFirst().first
                    guard let idString, let calendarId = UUID(uuidString: idString) else { return }

                    let store = CustomCalendarStore.shared
                    let calendars = CustomCalendarStore.fetchCalendarsSnapshot()
                    guard let calendar = calendars.first(where: { $0.id == calendarId }) else { return }

                    quickEntry(calendar: calendar, date: Date(), calendarStore: store)
                    WidgetReload.scheduleAllTimelinesReload()
                default:
                    break
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
