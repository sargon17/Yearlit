//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import SharedModels
import SwiftfulRouting
import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = CustomCalendarStore.shared
    @State private var notificationCoordinator = NotificationRefreshCoordinator()
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var onboarding: OnboardingManager
    @AppStorage(AppStorageKeys.appleHealthIntegrationEnabled)
    private var appleHealthIntegrationEnabled = false
    private let appleHealthSyncService = AppleHealthCalendarSyncService()

    var body: some View {
        let snapshot = store.snapshot

        AppRouter()
            .onChange(of: snapshot.dataVersion) { _, newVersion in
                notificationCoordinator.calendarDataVersionChanged(to: newVersion)
            }
            .task {
                await notificationCoordinator.appLaunched(onboardingSeen: onboarding.hasSeenOnboarding)
                guard appleHealthIntegrationEnabled else { return }
                await appleHealthSyncService.syncAllConnectedCalendars()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                notificationCoordinator.appBecameActive(onboardingSeen: onboarding.hasSeenOnboarding)
                guard appleHealthIntegrationEnabled else { return }
                Task {
                    await appleHealthSyncService.syncAllConnectedCalendars()
                }
            }
            .onChange(of: onboarding.hasSeenOnboarding) { _, hasSeenOnboarding in
                notificationCoordinator.onboardingSeenChanged(to: hasSeenOnboarding)
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationAuthorizationChanged)) { _ in
                notificationCoordinator.notificationAuthorizationChanged(onboardingSeen: onboarding.hasSeenOnboarding)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .font(AppFont.mono(17))
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingManager())
}
