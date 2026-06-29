import SharedModels
import SwiftUI

extension CustomCalendarView {
  func scheduleMilestoneCheck() {
    pendingMilestoneCheck = true
  }

  func evaluateMilestonesIfNeeded(calendarId: UUID) {
    guard pendingMilestoneCheck else { return }
    pendingMilestoneCheck = false
    let referenceDate = Date()
    guard let updatedCalendar = store.snapshot.calendar(id: calendarId) else { return }
    let currentStreak = currentStreak(for: updatedCalendar)
    let snapshot = renderSnapshot

    let context = CustomCalendarMilestoneContext(
      calendar: updatedCalendar,
      currentStreak: currentStreak,
      visibleGridDates: snapshot.visibleGridDates,
      calendarYearGridDates: snapshot.calendarYearGridDates,
      referenceDate: referenceDate,
      policy: milestoneCelebrationPolicy
    )
    guard let presentation = CustomCalendarMilestoneResolver.presentation(for: context) else { return }

    presentMilestoneCelebration(calendar: updatedCalendar, presentation: presentation)
  }

  func currentStreak(for calendar: CustomCalendar) -> Int {
    WidgetStreak.currentStreak(calendar: calendar).streak
  }
}
