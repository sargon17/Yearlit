import SharedModels
import SwiftUI

extension CreateManualCalendarView {
  var createFormContent: some View {
    VStack(spacing: 32) {
      CustomSeparator()
        .padding(.horizontal, -16)
      identitySection
      cadenceSection
      trackingSection
      valueSettingsSection
      notificationSection
      historySection
      CustomSeparator()
        .padding(.horizontal, -16)
    }
  }

  var identitySection: some View {
    CalendarIdentityLCDSection(
      name: $name,
      selectedColor: $selectedColor,
      prompt: "Daily Training",
      isNameFocused: $isNameFocused
    )
  }

  var cadenceSection: some View {
    VStack(spacing: 32) {
      CalendarCadencePicker(
        cadence: cadence,
        color: Color(selectedColor),
        isEditable: true
      ) { selectedCadence in
        if selectedCadence != cadence {
          clearExistingStreakHistory()
        }
        cadence = selectedCadence
      }

      AnimatedPickerDescription(text: cadence.detailDescription, id: cadence)
    }
  }

  var trackingSection: some View {
    VStack(spacing: 32) {
      TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))

      AnimatedPickerDescription(
        text: trackingType.detailDescription(for: cadence),
        id: trackingType,
        bottomPadding: 12
      )
    }
  }

  @ViewBuilder
  var valueSettingsSection: some View {
    if usesValueSettings {
      CalendarValueSettingsSection(
        label: LocalizedStringKey("Settings for \(trackingType.displayName)"),
        targetLabel: cadence.targetTitle,
        showsTarget: trackingType == .multipleDaily,
        showsUnitSettings: true,
        color: Color(selectedColor),
        dailyTarget: $dailyTarget,
        selectedUnit: $selectedUnit,
        currencySymbol: $currencySymbol,
        defaultRecordValue: $defaultRecordValue
      )
    }
  }

  var notificationSection: some View {
    CustomSection(label: "Notifications") {
      VStack(spacing: 2) {
        NotificationSettingsRow(
          summary: NotificationSettingsHelpers.reminderSummary(
            isEnabled: notificationSettings.recurringReminderEnabled,
            cadence: cadence,
            reminderTime: notificationSettings.reminderTime,
            reminderWeekday: notificationSettings.reminderWeekday
          ),
          onTap: { showingNotificationSettings = true }
        )
      }
      .padding(.all, 2)
    }
  }

  var historySection: some View {
    HabitHistorySection(
      cadence: cadence,
      trackingStartedAt: $trackingStartedAt,
      earliestEntryDate: earliestExistingEntryDate,
      autoAdjustedMessage: historyMessage ?? (!existingStreakEntries.isEmpty ? backfillSummary : nil),
      onTrackingStartedAtChanged: { historyMessage = nil },
      onAddExistingStreak: showExistingStreakSheet
    )
  }

  var notificationSettingsSheet: some View {
    NotificationSettingsDraftSheet(
      calendarName: name,
      cadence: cadence,
      trackingType: trackingType,
      accentColor: Color(selectedColor),
      customerInfo: customerInfo,
      draft: notificationSettings
    ) { draft in
      notificationSettings = draft
    }
  }
}
