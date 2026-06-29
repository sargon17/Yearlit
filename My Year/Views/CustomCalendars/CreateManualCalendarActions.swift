import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

extension CreateManualCalendarView {
  @ToolbarContentBuilder
  var createToolbar: some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button("Create") {
        Task {
          if await handleCreateCalendar() {
            router.dismissEnvironment()
          }
        }
      }
      .disabled(trimmedName.isEmpty)
    }
  }

  func createCalendar() {
    let calendar = CustomCalendar(
      name: trimmedName,
      color: selectedColor,
      cadence: cadence,
      trackingType: trackingType,
      trackingStartedAt: resolvedTrackingStartedAt(),
      dailyTarget: normalizedDailyTarget,
      entries: existingStreakEntries,
      isArchived: false,
      recurringReminderEnabled: notificationSettings.recurringReminderEnabled,
      reminderTime: notificationSettings.recurringReminderEnabled ? notificationSettings.reminderTime : nil,
      reminderWeekday: notificationSettings.recurringReminderEnabled && cadence == .weekly
        ? notificationSettings.reminderWeekday : nil,
      unit: usesValueSettings ? selectedUnit : nil,
      defaultRecordValue: usesValueSettings ? defaultRecordValue : nil,
      currencySymbol: usesValueSettings && selectedUnit == .currency ? currencySymbol : nil,
      reminderTimeZone: TimeZone.current.identifier,
      notificationPrivacyMode: notificationSettings.notificationPrivacyMode,
      suppressWhenCompleted: notificationSettings.suppressWhenCompleted,
      additionalReminderTimes: trackingType == .multipleDaily && isPremiumUser
        ? notificationSettings.additionalReminderTimes : [],
      streakProtectionEnabled: notificationSettings.streakProtectionEnabled,
      streakProtectionThreshold: notificationSettings.streakProtectionThreshold,
      source: .manual
    )
    scheduleNotifications(for: calendar, store: CustomCalendarStore.shared)
    onCreate(calendar)
  }

  @MainActor
  func handleCreateCalendar() async -> Bool {
    if !userCanCreateCalendar() {
      router.showScreen(.sheet) { _ in
        PremiumPaywallSheet(displayCloseButton: true, trigger: .calendarLimit)
      }
      return false
    }

    createCalendar()
    return true
  }

  func showExistingStreakSheet() {
    router.showScreen(.sheet) { _ in
      ExistingStreakSheet(
        cadence: cadence,
        trackingType: trackingType,
        dailyTarget: normalizedDailyTarget,
        defaultDailyValue: defaultRecordValue,
        existingEntries: existingStreakEntries,
        accentColor: Color(selectedColor)
      ) { entries in
        applyExistingStreakEntries(entries)
      }
    }
  }
}
