import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

extension CustomCalendarView {
  func presentEntryEditSheet(calendar: CustomCalendar, date: Date) {
    guard !calendar.isAppleHealthConnected else { return }
    let sheetDate = entrySheetDate(for: date, cadence: calendar.cadence)
    Task {
      await hapticFeedback()
    }
    isEntryEditSheetPresented = true
    router.showScreen(
      .sheetConfig(config: entryEditSheetConfig)
    ) { _ in
      DayEntryEditSheet(
        calendar: calendar,
        date: sheetDate,
        store: store,
        onSave: { entry in
          if isPositiveEntry(entry) {
            triggerCheckInRipple(from: entry.date)
          }
          scheduleMilestoneCheck()
        },
        onDismiss: {
          isEntryEditSheetPresented = false
          evaluateMilestonesIfNeeded(calendarId: calendar.id)
        }
      )
      .id(entrySheetIdentity(calendar: calendar, date: sheetDate))
    }
  }

  private func entrySheetIdentity(calendar: CustomCalendar, date: Date) -> String {
    [
      calendar.id.uuidString,
      calendar.cadence.rawValue,
      String(date.timeIntervalSinceReferenceDate)
    ].joined(separator: "-")
  }

  private func entrySheetDate(for date: Date, cadence: CalendarCadence) -> Date {
    switch cadence {
    case .daily:
      return LocalDayCalendar.startOfDay(for: date)
    case .weekly:
      return LocalDayCalendar.startOfWeek(for: date)
    }
  }

  func presentMilestoneCelebration(
    calendar: CustomCalendar,
    presentation: CustomCalendarMilestonePresentation
  ) {
    router.showScreen(.sheet) { _ in
      MilestoneCelebrationSheet(
        calendar: calendar,
        milestone: presentation.milestone,
        currentStreak: presentation.currentStreak,
        kind: presentation.kind,
        dates: presentation.dates,
        allowsStopShowing: true,
        showedUpPeriodKey: presentation.showedUpPeriodKey
      )
    }
  }

  func presentEditCalendar(_ calendar: CustomCalendar) {
    router.showScreen(.sheet) { _ in
      EditCalendarView(
        calendar: calendar,
        onSave: { updatedCalendar in
          store.updateCalendar(updatedCalendar)
        },
        onDelete: { _ in
          store.deleteCalendar(id: calendar.id)
        }
      )
    }
  }

  func presentNotificationSettings(for calendar: CustomCalendar) {
    router.showScreen(.sheet) { _ in
      NotificationSettingsSheet(
        calendar: calendar,
        customerInfo: customerInfo,
        onSave: { updatedCalendar in
          store.updateCalendar(updatedCalendar)
        }
      )
    }
  }

  func presentCalendarShareSheet(
    calendar: CustomCalendar,
    renderSnapshot: CalendarRenderSnapshot
  ) {
    router.showScreen(.sheet) { _ in
      CalendarShareSheet(
        calendar: calendar,
        year: valuationStore.selectedYear,
        dates: renderSnapshot.calendarYearGridDates,
        statsBundle: statsBundle,
        isPremium: isPremium(customerInfo: customerInfo)
      )
    }
  }
}
