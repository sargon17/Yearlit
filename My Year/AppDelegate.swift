import SharedModels
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    setupNotificationCategories()
    return true
  }

  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      openNotificationCalendar(response)
    } else {
      Task { @MainActor in
        handleNotificationAction(response, store: CustomCalendarStore.shared)
      }
    }

    completionHandler()
  }

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
        completionHandler([])
        return
      }

      completionHandler([.banner, .sound, .badge])
    }
  }

  private func openNotificationCalendar(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo
    guard let calendarIdString = userInfo["calendarId"] as? String,
      let calendarId = UUID(uuidString: calendarIdString),
      let deepLinkURL = URL(string: "my-year://calendar/\(calendarId.uuidString)")
    else { return }

    UIApplication.shared.open(deepLinkURL)
  }
}
