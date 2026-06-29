import SharedModels
import SwiftUI

struct PrivacySection: View {
  let style: NotificationSettingsStyle
  let accentColor: Color
  @Binding var notificationPrivacyMode: NotificationPrivacyMode

  var body: some View {
    NotificationSettingsSection(
      label: "Privacy",
      description: style == .saved ? "Determines how the notifications appear on your lock screen." : nil,
      style: style
    ) {
      switch style {
      case .saved:
        VStack {
          HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Lock screen text")
                .labelStyle(type: .secondary)
              Text(notificationPrivacyMode.detail)
                .descriptionStyle()
            }
            Spacer()
          }
          .padding(.horizontal)

          Picker("Privacy Level", selection: $notificationPrivacyMode) {
            ForEach(NotificationPrivacyMode.allCases, id: \.self) { mode in
              Text(mode.description).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .font(AppFont.mono(12))
          .padding(.horizontal, 6)
        }
        .padding(.vertical, 12)
        .notificationSurface()

      case .draft:
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Lock screen text")
              .labelStyle(type: .secondary)
            Text(notificationPrivacyMode.detail)
              .font(.caption)
              .foregroundStyle(.textTertiary)
          }
          Spacer()
          Picker("Privacy Level", selection: $notificationPrivacyMode) {
            ForEach(NotificationPrivacyMode.allCases, id: \.self) { mode in
              Text(mode.description).tag(mode)
            }
          }
          .pickerStyle(.menu)
          .tint(accentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .notificationSurface()
      }
    }
  }
}

struct ReminderBehaviorSection: View {
  let cadence: CalendarCadence
  let accentColor: Color
  let style: NotificationSettingsStyle

  @Binding var suppressWhenCompleted: Bool
  @Binding var streakProtectionEnabled: Bool

  var body: some View {
    if style == .saved {
      NotificationSettingsSection(
        label: "Streak Protection",
        description: cadence == .weekly
          ? "We will send you a reminder when you're about to miss the week."
          : "We will send you a reminder when you're about to miss a day.",
        style: style
      ) {
        streakProtectionRow
        suppressionRow
      }
    } else {
      NotificationSettingsSection(label: "Behavior", style: style) {
        suppressionRow
        streakProtectionRow
      }
    }
  }

  private var streakProtectionRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Late-day rescue reminder")
          .labelStyle(type: .secondary)
        if style == .draft {
          Text(
            cadence == .weekly
              ? "On the last day of the week at 9 PM, if your streak is at risk, we send one extra reminder."
              : "At 9 PM, if your streak is at risk, we send one extra reminder."
          )
          .font(.caption)
          .foregroundStyle(.textTertiary)
        }
      }
      Spacer()
      Toggle("", isOn: $streakProtectionEnabled)
    }
    .tint(accentColor)
    .padding(.horizontal)
    .padding(.vertical, 10)
    .notificationSurface()
  }

  private var suppressionRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Smart suppression")
          .labelStyle(type: .secondary)
        Text(
          cadence == .weekly
            ? "While the app is open, hides reminders if you've already logged this week."
            : "While the app is open, hides reminders if you've already logged today."
        )
        .font(.caption)
        .foregroundStyle(.textTertiary)
      }
      Spacer()
      Toggle("", isOn: $suppressWhenCompleted)
    }
    .tint(accentColor)
    .padding(.horizontal)
    .padding(.vertical, 10)
    .notificationSurface()
  }
}
