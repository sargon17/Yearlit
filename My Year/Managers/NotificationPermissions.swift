import Foundation
@preconcurrency import SharedModels
import UserNotifications

// MARK: - Notification Cleanup

/// Removes notifications for calendars that no longer exist.
public func checkForNotificationsOfNonExistingCalendars(store: CustomCalendarStore) async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let calendarIds = await MainActor.run {
        Set(store.snapshot.calendars.map { $0.id.uuidString })
    }

    var removedCount = 0
    for request in requests {
        guard let requestCalendarId = deriveCalendarId(from: request) else {
            continue
        }

        if !calendarIds.contains(requestCalendarId.uuidString) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [request.identifier]
            )
            removedCount += 1
        }
    }
}

// MARK: - Smart Suppression

/// Checks if a notification should be suppressed because the current period is already completed.
@MainActor
public func shouldSuppressNotification(for calendar: CustomCalendar, store: CustomCalendarStore) -> Bool {
    let today = Date()

    guard let entry = store.getEntry(calendarId: calendar.id, date: today) else {
        return false
    }

    return isEntryFulfilledForNotification(entry, calendar: calendar)
}

// MARK: - Permission Helpers

/// Checks if notification permissions are granted.
public func checkNotificationPermissions(
    completion: @escaping (Bool) -> Void
) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        let isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        completion(isAuthorized)
    }
}

/// Requests notification permissions if not already granted.
public func requestNotificationPermissions(
    completion: @escaping (Result<Bool, Error>) -> Void
) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .notDetermined:
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(granted))
                }

                NotificationCenter.default.post(name: .notificationAuthorizationChanged, object: nil)
            }

        case .authorized, .provisional:
            completion(.success(true))

        default:
            completion(.success(false))
        }
    }
}
