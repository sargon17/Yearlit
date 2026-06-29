import SharedModels
import SwiftUI

extension EditCalendarView {
  var editFormContent: some View {
    VStack(spacing: 32) {
      CustomSeparator()
        .padding(.horizontal, -16)
      identitySection
      trackingConfigurationSection
      valueSettingsSection
      notificationSection
      historySection
      dangerZoneDivider
      dangerZoneSection
      CustomSeparator()
        .padding(.horizontal, -16)
    }
  }

  var identitySection: some View {
    VStack(spacing: 32) {
      CalendarIdentityLCDSection(
        name: $name,
        selectedColor: $selectedColor,
        prompt: "Daily Training",
        isNameFocused: $isNameFocused
      )

      CalendarCadencePicker(cadence: cadence, color: Color(selectedColor), isEditable: false) { _ in }

      Text("Cadence can't be changed after creation.")
        .font(.footnote)
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
  }

  @ViewBuilder
  var trackingConfigurationSection: some View {
    if isAppleHealthCalendar {
      lockedAppleHealthMetricSection
    } else {
      TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))
    }

    AnimatedPickerDescription(
      text: trackingType.detailDescription(for: cadence),
      id: trackingType,
      bottomPadding: 12
    )
  }

  @ViewBuilder
  var valueSettingsSection: some View {
    if isAppleHealthCalendar || trackingType == .multipleDaily || trackingType == .counter {
      CalendarValueSettingsSection(
        label: settingsSectionLabel,
        targetLabel: targetFieldLabel,
        showsTarget: isAppleHealthCalendar || trackingType == .multipleDaily,
        showsUnitSettings: usesManualValueSettings,
        color: Color(selectedColor),
        dailyTarget: $dailyTarget,
        selectedUnit: $selectedUnit,
        currencySymbol: $currencySymbol,
        defaultRecordValue: $defaultRecordValue
      )
    }
  }

  @ViewBuilder
  var notificationSection: some View {
    if !isAppleHealthCalendar {
      CustomSection(label: "Notifications") {
        VStack(spacing: 2) {
          NotificationSettingsRow(
            summary: notificationSummary,
            onTap: { showingNotificationSettings = true }
          )
        }
        .padding(.all, 2)
      }
    }
  }

  var notificationSummary: String {
    NotificationSettingsHelpers.reminderSummary(
      isEnabled: notificationSettings.recurringReminderEnabled,
      cadence: cadence,
      reminderTime: notificationSettings.reminderTime,
      reminderWeekday: notificationSettings.reminderWeekday
    )
  }

  @ViewBuilder
  var historySection: some View {
    if !isAppleHealthCalendar {
      HabitHistorySection(
        cadence: cadence,
        trackingStartedAt: $trackingStartedAt,
        earliestEntryDate: earliestExistingEntryDate,
        autoAdjustedMessage: historyMessage,
        onTrackingStartedAtChanged: { historyMessage = nil },
        onAddExistingStreak: showExistingStreakSheet
      )
    }
  }

  var dangerZoneDivider: some View {
    CustomSeparator()
      .padding(.horizontal, -16)
      .padding(.vertical, 16)
  }

  var dangerZoneSection: some View {
    CalendarDangerZoneSection(
      isArchived: isArchived,
      showingDeleteConfirmation: $showingDeleteConfirmation,
      onArchiveToggle: toggleArchive,
      onDelete: deleteCalendar
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
