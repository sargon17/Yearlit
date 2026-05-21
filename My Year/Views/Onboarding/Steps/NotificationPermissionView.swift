import Garnish
import SwiftUI

struct NotificationPermissionView: View {
  let isRequestingNotifications: Bool
  let onTurnOnReminders: () -> Void
  let onNotNow: () -> Void

  var body: some View {
    OnboardingStepContainer {
      Color.clear
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingView.Title("One last thing.")
        OnboardingView.Caption("Yearlit can remind you to keep your promise.")
        OnboardingView.Caption("A gentle daily nudge helps your dots keep growing.")
          .padding(.bottom)
        OnboardingView.Caption(" After this, your year is ready.")
      }
    } actions: {
      VStack(spacing: 2) {
        OnboardingView.ForwardButton(
          title: isRequestingNotifications ? "Requesting..." : "Turn on reminders",
          onTap: onTurnOnReminders,
          style: isRequestingNotifications ? .disabled : .primary
        )
        OnboardingView.ForwardButton(
          title: "Not now",
          onTap: onNotNow,
          style: isRequestingNotifications ? .disabled : .secondary
        )
      }
    }
  }
}
