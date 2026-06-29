import SharedModels
import SwiftUI

struct ReminderScheduleSection: View {
  let cadence: CalendarCadence
  let accentColor: Color
  let style: NotificationSettingsStyle

  @Binding var recurringReminderEnabled: Bool
  @Binding var reminderTime: Date
  @Binding var reminderWeekday: Int

  var body: some View {
    NotificationSettingsSection(
      label: cadence == .weekly ? "Weekly Reminder" : "Daily Reminder",
      description: cadence == .weekly
        ? "A recurring notification on your chosen weekday and time."
        : "A recurring notification at your chosen time.",
      style: style
    ) {
      toggleRow

      if recurringReminderEnabled {
        if cadence == .weekly {
          weekdayRow
        }
        timeRow
      }
    }
  }

  private var toggleRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(String(localized: cadence == .weekly ? "Send a weekly reminder" : "Send a daily reminder"))
          .labelStyle(type: .secondary)
      }
      Spacer()
      Toggle("", isOn: $recurringReminderEnabled)
    }
    .tint(accentColor)
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
  }

  private var weekdayRow: some View {
    HStack {
      Text("Weekday")
        .labelStyle(type: .secondary)
      Spacer()
      Picker("Weekday", selection: $reminderWeekday) {
        ForEach(NotificationSettingsHelpers.orderedWeekdays(), id: \.self) { weekday in
          Text(NotificationSettingsHelpers.weekdayName(weekday)).tag(weekday)
        }
      }
      .pickerStyle(.menu)
      .tint(accentColor)
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .notificationSurface()
  }

  @ViewBuilder
  private var timeRow: some View {
    switch style {
    case .saved:
      HStack(spacing: 6) {
        DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
          .tint(accentColor)
          .datePickerStyle(.compact)
          .labelsHidden()
        Spacer()
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .notificationSurface()

    case .draft:
      VStack(spacing: 6) {
        HStack {
          Text("Time")
            .labelStyle(type: .secondary)
          Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)

        DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
          .labelsHidden()
          .tint(accentColor)
          .datePickerStyle(.wheel)
          .inputStyle(radius: 4, color: accentColor)
          .colorScheme(.dark)
          .padding(.horizontal)
          .padding(.bottom, 10)
      }
      .notificationSurface()
    }
  }
}
