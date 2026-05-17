//
//  NotificationRefreshCoordinator.swift
//  My Year
//
//  Created by Pi on 17/05/26.
//

import Foundation
import SharedModels

@MainActor
final class NotificationRefreshCoordinator {
    private let store: CustomCalendarStore
    private var lastCleanupVersion: Int = -1
    private var cleanupTask: Task<Void, Never>?

    init(store: CustomCalendarStore? = nil) {
        self.store = store ?? CustomCalendarStore.shared
    }

    deinit {
        cleanupTask?.cancel()
    }

    func appLaunched(onboardingSeen: Bool) async {
        await checkForNotificationsOfNonExistingCalendars(store: store)
        refreshStreakProtectionReminders(store: store)
        await refreshRetentionNotificationsIfNeeded(onboardingSeen: onboardingSeen)
    }

    func appBecameActive(onboardingSeen: Bool) {
        refreshStreakProtectionReminders(store: store)
        Task {
            await refreshRetentionNotificationsIfNeeded(onboardingSeen: onboardingSeen)
        }
    }

    func calendarDataVersionChanged(to newVersion: Int) {
        cleanupTask?.cancel()
        cleanupTask = Task {
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled,
                  lastCleanupVersion != newVersion
            else { return }

            lastCleanupVersion = newVersion
            await checkForNotificationsOfNonExistingCalendars(store: store)
            refreshStreakProtectionReminders(store: store)
        }
    }

    func onboardingSeenChanged(to onboardingSeen: Bool) {
        Task {
            await refreshRetentionNotificationsIfNeeded(onboardingSeen: onboardingSeen)
        }
    }
}
