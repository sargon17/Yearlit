import SharedModels
import SwiftUI

extension CustomCalendarView {
  @MainActor
  func syncAppleHealth(calendar: CustomCalendar, showsErrors: Bool = false) async {
    guard calendar.isAppleHealthConnected else { return }
    guard !isSyncingAppleHealth else { return }
    isSyncingAppleHealth = true
    defer { isSyncingAppleHealth = false }

    do {
      if let result = try await appleHealthSyncService.sync(calendar: calendar) {
        CustomCalendarMilestoneResolver.rememberMilestonesSilently(
          for: result.calendar,
          replacingEntries: result.entries,
          from: result.start,
          through: result.end,
          policy: milestoneCelebrationPolicy
        )
      }
    } catch {
      if showsErrors {
        calendarError = .appleHealthSyncFailed(error)
      }
    }
  }
}
