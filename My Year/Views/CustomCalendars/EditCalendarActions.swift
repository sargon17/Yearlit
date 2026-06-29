import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

extension EditCalendarView {
  @ToolbarContentBuilder
  var editToolbar: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button("Cancel") {
        dismiss()
      }
    }
    ToolbarItem(placement: .confirmationAction) {
      Button("Save", action: saveCalendar)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }

  func loadCustomerInfo() {
    guard RevenueCatClient.isConfigured else { return }

    Purchases.shared.getCustomerInfo { info, _ in
      customerInfo = info
    }
  }

  func showExistingStreakSheet() {
    router.showScreen(.sheet) { _ in
      ExistingStreakSheet(
        cadence: cadence,
        trackingType: trackingType,
        dailyTarget: normalizedDailyTarget,
        defaultDailyValue: defaultRecordValue,
        existingEntries: entries,
        accentColor: Color(selectedColor)
      ) { newEntries in
        applyExistingStreakEntries(newEntries)
      }
    }
  }

  func saveCalendar() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty && trimmedName.count <= 50 else {
      calendarError = .invalidName
      return
    }
    let updatedCalendar = makeUpdatedCalendar()
    if !isAppleHealthCalendar {
      scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
    }
    onSave(updatedCalendar)
    if calendar.isArchived != updatedCalendar.isArchived {
      CalendarAnalyticsTracker.shared.trackArchiveStateChange(
        calendar: updatedCalendar,
        source: .editCalendar,
        isArchived: updatedCalendar.isArchived
      )
    }
    dismiss()
  }

  func toggleArchive() {
    isArchived.toggle()
    let updatedCalendar = makeUpdatedCalendar(isArchived: isArchived)
    if !isAppleHealthCalendar {
      scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
    }
    onSave(updatedCalendar)
    CalendarAnalyticsTracker.shared.trackArchiveStateChange(
      calendar: updatedCalendar,
      source: .editCalendar,
      isArchived: updatedCalendar.isArchived
    )
    dismiss()
  }

  func deleteCalendar() {
    onDelete(calendar)
    cancelNotifications(for: calendar)
    dismiss()
  }
}
