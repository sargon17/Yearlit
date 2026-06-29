import SharedModels
import SwiftUI

extension CustomCalendarView {
  func fillRandomEntries() {
    CustomCalendarDebugEntryFiller.fill(
      snapshot: renderSnapshot,
      today: today,
      force: wandFillForce,
      store: store
    )
  }

  func setOptimisticEntryOverride(calendar: CustomCalendar, date: Date, entry: CalendarEntry?) {
    let override = CustomCalendarOptimisticEntries.override(for: calendar, date: date, entry: entry)
    optimisticEntryOverrides[override.key] = override.value
  }

  func isPositiveEntry(_ entry: CalendarEntry?) -> Bool {
    guard let entry else { return false }
    return entry.hasLoggedCount || entry.completed
  }

  func triggerCheckInRipple(from date: Date) {
    checkInRippleOriginDate = date
    checkInRippleTrigger += 1
    Task { @MainActor in
      await checkInRippleHapticFeedback()
    }
  }

  func handleDayTap(_ date: Date) {
    guard !date.isInFuture else { return }

    let activeCalendar = renderSnapshot.activeCalendar
    guard !activeCalendar.isAppleHealthConnected else { return }

    if activeCalendar.trackingType == .binary {
      handleBinaryDayTap(date, calendar: activeCalendar)
      return
    }

    presentEntryEditSheet(calendar: activeCalendar, date: date)
  }

  private func handleBinaryDayTap(_ date: Date, calendar: CustomCalendar) {
    let isCheckingIn = calendar.entry(for: date) == nil
    let newEntry =
      isCheckingIn
      ? defaultEntry(date: date, trackingType: .binary)
      : nil
    setOptimisticEntryOverride(calendar: calendar, date: date, entry: newEntry)

    Task { @MainActor in
      await hapticFeedback()
      _ = toggleBinaryEntry(
        calendarId: calendar.id,
        date: date,
        calendarStore: store,
        source: .calendar
      )
      if isCheckingIn {
        triggerCheckInRipple(from: date)
      }
      scheduleMilestoneCheck()
      checkIfReachedThreeDays(calendar)
    }
  }

  func handleQuickAdd() {
    let state = renderSnapshot
    guard let date = state.currentPeriodReferenceDate else { return }
    handleQuickAdd(calendar: state.activeCalendar, date: date)
  }

  func handleQuickAdd(calendar: CustomCalendar, date: Date) {
    guard !calendar.isAppleHealthConnected else { return }

    Task { @MainActor in
      await hapticFeedback()
      _ = try? CalendarShortcutService.checkIn(
        calendar: calendar,
        date: date,
        value: nil,
        store: store,
        source: .calendar
      )
      if isPositiveEntry(store.getEntry(calendarId: calendar.id, date: date)) {
        triggerCheckInRipple(from: date)
      }

      checkIfReachedThreeDays(calendar)
      scheduleMilestoneCheck()
    }
  }
}
