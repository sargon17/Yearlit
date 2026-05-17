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

    var body: some View {
        let snapshot = store.snapshot

        AppRouter()
            .onChange(of: snapshot.dataVersion) { _, newVersion in
                notificationCoordinator.calendarDataVersionChanged(to: newVersion)
            }
            .task {
                await notificationCoordinator.appLaunched(onboardingSeen: onboarding.hasSeenOnboarding)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                notificationCoordinator.appBecameActive(onboardingSeen: onboarding.hasSeenOnboarding)
            }
            .onChange(of: onboarding.hasSeenOnboarding) { _, hasSeenOnboarding in
                notificationCoordinator.onboardingSeenChanged(to: hasSeenOnboarding)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .font(AppFont.mono(17))
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingManager())
}
