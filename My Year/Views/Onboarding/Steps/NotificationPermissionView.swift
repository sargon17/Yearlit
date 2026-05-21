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
        Spacer()
        Text("Turn on reminders.")
          .font(AppFont.pixelCircle(24))
          .foregroundStyle(.textPrimary)
        Text("You can change this later in Settings.")
          .font(AppFont.mono(14))
          .foregroundStyle(.secondary)
      }
    } actions: {
      VStack(spacing: 12) {
        OnboardingView.ForwardButton(
          title: isRequestingNotifications ? "Requesting..." : "Turn on reminders",
          onTap: onTurnOnReminders,
          style: isRequestingNotifications ? .disabled : .primary
        )
        OnboardingView.ForwardButton(
          title: "Not now",
          onTap: onNotNow,
          style: isRequestingNotifications ? .disabled : .primary
        )
      }
    }
  }
}
