//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftData
import SwiftfulRouting
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var customerInfo: CustomerInfo?
    @ObservedObject private var store = CustomCalendarStore.shared
    @State private var lastCleanupVersion: Int = -1
    @State private var cleanupTask: Task<Void, Never>?
    @EnvironmentObject private var whatsNewManager: WhatsNewManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let snapshot = store.snapshot

        AppRouter()
            .onAppear {
                Purchases.shared.getCustomerInfo { customerInfo, _ in
                    self.customerInfo = customerInfo
                }
            }
            .onReceive(store.$snapshot) { snapshot in
                whatsNewManager.evaluateIfNeeded(
                    hasCalendars: !snapshot.calendars.isEmpty,
                    isLoading: snapshot.isLoading
                )
            }
            .onChange(of: snapshot.dataVersion) { _, newVersion in
                // Debounce cleanup to avoid excessive IPC calls
                cleanupTask?.cancel()
                cleanupTask = Task {
                    // Wait 2 seconds to batch multiple rapid changes
                    try? await Task.sleep(for: .seconds(2))

                    // Check if still needed and not cancelled
                    guard !Task.isCancelled,
                          lastCleanupVersion != newVersion
                    else { return }

                    lastCleanupVersion = newVersion
                    await checkForNotificationsOfNonExistingCalendars(store: store)
                    refreshStreakProtectionReminders(store: store)
                }
            }
            .task {
                // Initial cleanup on app launch
                await checkForNotificationsOfNonExistingCalendars(store: store)
                refreshStreakProtectionReminders(store: store)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                refreshStreakProtectionReminders(store: store)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .font(.system(.body, design: .monospaced))
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(WhatsNewManager())
}
