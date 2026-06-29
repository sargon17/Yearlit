import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct NotificationSettingsDraft {
  var recurringReminderEnabled: Bool
  var reminderTime: Date
  var notificationPrivacyMode: NotificationPrivacyMode
  var suppressWhenCompleted: Bool
  var additionalReminderTimes: [ReminderTime]
  var streakProtectionEnabled: Bool
  var streakProtectionThreshold: Int
  var reminderWeekday: Int
}

extension NotificationSettingsDraft {
  static func manualDefault(reminderWeekday: Int) -> NotificationSettingsDraft {
    NotificationSettingsDraft(
      recurringReminderEnabled: false,
      reminderTime: Date(),
      notificationPrivacyMode: .full,
      suppressWhenCompleted: true,
      additionalReminderTimes: [],
      streakProtectionEnabled: true,
      streakProtectionThreshold: 5,
      reminderWeekday: reminderWeekday
    )
  }

  init(
    calendar: CustomCalendar,
    fallbackReminderTime: Date,
    fallbackReminderWeekday: Int
  ) {
    self.init(
      recurringReminderEnabled: calendar.recurringReminderEnabled,
      reminderTime: Self.reminderDate(for: calendar, fallback: fallbackReminderTime),
      notificationPrivacyMode: calendar.notificationPrivacyMode,
      suppressWhenCompleted: calendar.suppressWhenCompleted,
      additionalReminderTimes: calendar.additionalReminderTimes,
      streakProtectionEnabled: calendar.streakProtectionEnabled,
      streakProtectionThreshold: calendar.streakProtectionThreshold,
      reminderWeekday: calendar.reminderWeekday ?? fallbackReminderWeekday
    )
  }

  private static func reminderDate(for calendar: CustomCalendar, fallback: Date) -> Date {
    guard
      calendar.recurringReminderEnabled,
      let hour = calendar.reminderHour,
      let minute = calendar.reminderMinute
    else {
      return fallback
    }

    return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? fallback
  }
}

struct NotificationSettingsDraftSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router

  let calendarName: String
  let cadence: CalendarCadence
  let trackingType: TrackingType
  let accentColor: Color
  let customerInfo: CustomerInfo?
  let onSave: (NotificationSettingsDraft) -> Void

  @State private var draft: NotificationSettingsDraft

  init(
    calendarName: String,
    cadence: CalendarCadence,
    trackingType: TrackingType,
    accentColor: Color,
    customerInfo: CustomerInfo?,
    draft: NotificationSettingsDraft,
    onSave: @escaping (NotificationSettingsDraft) -> Void
  ) {
    self.calendarName = calendarName
    self.cadence = cadence
    self.trackingType = trackingType
    self.accentColor = accentColor
    self.customerInfo = customerInfo
    self.onSave = onSave
    _draft = State(initialValue: draft)
  }

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          ReminderScheduleSection(
            cadence: cadence,
            accentColor: accentColor,
            style: .draft,
            recurringReminderEnabled: $draft.recurringReminderEnabled,
            reminderTime: $draft.reminderTime,
            reminderWeekday: $draft.reminderWeekday
          )

          if draft.recurringReminderEnabled {
            AdditionalRemindersSection(
              cadence: cadence,
              trackingType: trackingType,
              accentColor: accentColor,
              isPremiumUser: isPremiumUser,
              style: .draft,
              onUpgrade: showPremiumPaywall,
              additionalReminderTimes: $draft.additionalReminderTimes,
              reminderTime: $draft.reminderTime
            )

            ReminderBehaviorSection(
              cadence: cadence,
              accentColor: accentColor,
              style: .draft,
              suppressWhenCompleted: $draft.suppressWhenCompleted,
              streakProtectionEnabled: $draft.streakProtectionEnabled
            )

            PrivacySection(
              style: .draft,
              accentColor: accentColor,
              notificationPrivacyMode: $draft.notificationPrivacyMode
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
          Button("Done") {
            var savedDraft = draft
            savedDraft.additionalReminderTimes =
              (cadence == .daily && trackingType == .multipleDaily && isPremiumUser)
              ? NotificationSettingsHelpers.sanitizedAdditionalReminderTimes(
                savedDraft.additionalReminderTimes,
                cadence: cadence,
                trackingType: trackingType
              )
              : []
            onSave(savedDraft)
            dismiss()
          }
        }
      }
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
    }
  }
}

extension NotificationSettingsDraftSheet {
  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      PremiumPaywallSheet(displayCloseButton: true, trigger: .notificationGate)
    }
  }
}
