import Garnish
import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct NotificationSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router

  let calendar: CustomCalendar
  let customerInfo: CustomerInfo?
  let onSave: (CustomCalendar) -> Void

  @State private var recurringReminderEnabled: Bool
  @State private var reminderTime: Date
  @State private var notificationPrivacyMode: NotificationPrivacyMode
  @State private var suppressWhenCompleted: Bool
  @State private var additionalReminderTimes: [ReminderTime]
  @State private var streakProtectionEnabled: Bool
  @State private var streakProtectionThreshold: Int
  @State private var reminderWeekday: Int

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  init(
    calendar: CustomCalendar,
    customerInfo: CustomerInfo?,
    onSave: @escaping (CustomCalendar) -> Void
  ) {
    self.calendar = calendar
    self.customerInfo = customerInfo
    self.onSave = onSave

    _recurringReminderEnabled = State(initialValue: calendar.recurringReminderEnabled)

    let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    if calendar.recurringReminderEnabled, let hour = calendar.reminderHour, let minute = calendar.reminderMinute {
      _reminderTime = State(
        initialValue: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime
      )
    } else {
      _reminderTime = State(initialValue: defaultTime)
    }

    _notificationPrivacyMode = State(initialValue: calendar.notificationPrivacyMode)
    _suppressWhenCompleted = State(initialValue: calendar.suppressWhenCompleted)
    _additionalReminderTimes = State(initialValue: calendar.additionalReminderTimes)
    _streakProtectionEnabled = State(initialValue: calendar.streakProtectionEnabled)
    _streakProtectionThreshold = State(initialValue: calendar.streakProtectionThreshold)
    _reminderWeekday = State(initialValue: calendar.reminderWeekday ?? Calendar.current.component(.weekday, from: Date()))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          VStack(alignment: .leading, spacing: 6) {
            betaBadge()
            Text(
              "Reminders are in beta and still evolving. Expect small changes, and occasional delays or misses while we tune reliability."
            )
            .descriptionStyle()
            .textCase(nil)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          ReminderScheduleSection(
            cadence: calendar.cadence,
            accentColor: Color(calendar.color),
            style: .saved,
            recurringReminderEnabled: $recurringReminderEnabled,
            reminderTime: $reminderTime,
            reminderWeekday: $reminderWeekday
          )

          if recurringReminderEnabled {
            AdditionalRemindersSection(
              cadence: calendar.cadence,
              trackingType: calendar.trackingType,
              accentColor: Color(calendar.color),
              isPremiumUser: isPremiumUser,
              style: .saved,
              onUpgrade: showPremiumPaywall,
              additionalReminderTimes: $additionalReminderTimes,
              reminderTime: $reminderTime
            )

            ReminderBehaviorSection(
              cadence: calendar.cadence,
              accentColor: Color(calendar.color),
              style: .saved,
              suppressWhenCompleted: $suppressWhenCompleted,
              streakProtectionEnabled: $streakProtectionEnabled
            )

            PrivacySection(
              style: .saved,
              accentColor: Color(calendar.color),
              notificationPrivacyMode: $notificationPrivacyMode
            )
          }
        }
        .padding()
      }
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { saveAndDismiss() }
        }
      }
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
    }
  }
}

extension NotificationSettingsSheet {
  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      PaywallView(displayCloseButton: true)
    }
  }

  private func proBadge() -> some View {
    let bgColor = GarnishColor.blend(.surfaceMuted, with: .moodExcellent, ratio: 0.2)
    let fgColor = GarnishColor.blend(.textPrimary, with: .moodExcellent, ratio: 0.5)
    let strokeStyle = StrokeStyle(
      lineWidth: 1, lineCap: .round, lineJoin: .bevel, miterLimit: 1, dash: [2], dashPhase: 3
    )

    return badge(text: "PRO", bgColor: bgColor, fgColor: fgColor, strokeStyle: strokeStyle)
  }

  private func betaBadge() -> some View {
    let bgColor = Color("surface-muted").opacity(0.4)
    let fgColor = Color.textTertiary

    return badge(text: "BETA", bgColor: bgColor, fgColor: fgColor, strokeStyle: nil)
  }

  private func badge(
    text: String,
    bgColor: Color,
    fgColor: Color,
    strokeStyle: StrokeStyle?
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: 4)

    return Text(text)
      .font(.system(size: 8, design: .monospaced))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        Group {
          if let strokeStyle {
            shape.stroke(style: strokeStyle)
          } else {
            shape.strokeBorder(fgColor, lineWidth: 1)
          }
        }
      )
      .background(bgColor)
      .foregroundColor(fgColor)
  }

  private func saveAndDismiss() {
    var updatedCalendar = calendar
    updatedCalendar.recurringReminderEnabled = recurringReminderEnabled

    if recurringReminderEnabled {
      let cal = Calendar.current
      updatedCalendar.reminderHour = cal.component(.hour, from: reminderTime)
      updatedCalendar.reminderMinute = cal.component(.minute, from: reminderTime)
      updatedCalendar.reminderWeekday = calendar.cadence == .weekly ? reminderWeekday : nil
    } else {
      updatedCalendar.reminderHour = nil
      updatedCalendar.reminderMinute = nil
      updatedCalendar.reminderWeekday = nil
    }

    updatedCalendar.notificationPrivacyMode = notificationPrivacyMode
    updatedCalendar.suppressWhenCompleted = suppressWhenCompleted
    updatedCalendar.additionalReminderTimes =
      (calendar.cadence == .daily && isPremiumUser && calendar.trackingType == .multipleDaily)
      ? NotificationSettingsHelpers.sanitizedAdditionalReminderTimes(
        additionalReminderTimes,
        cadence: calendar.cadence,
        trackingType: calendar.trackingType
      ) : []
    updatedCalendar.streakProtectionEnabled = streakProtectionEnabled
    updatedCalendar.streakProtectionThreshold = streakProtectionThreshold

    scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
    onSave(updatedCalendar)
    dismiss()
  }
}
