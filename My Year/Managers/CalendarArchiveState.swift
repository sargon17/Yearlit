import SharedModels

/// Sets the archive state on a calendar and keeps its notifications in sync.
func setArchiveState(
    _ isArchived: Bool,
    to calendar: CustomCalendar,
    store: CustomCalendarStore
) async throws -> CustomCalendar {
    var updatedCalendar = calendar
    updatedCalendar.isArchived = isArchived
    store.updateCalendar(updatedCalendar)
    try await rescheduleNotifications(for: updatedCalendar, store: store)
    return updatedCalendar
}
