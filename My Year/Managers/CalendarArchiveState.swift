import SharedModels

enum ArchiveStateError: Error {
    case persistenceFailed
}

/// Updates the archive state on a calendar and keeps its notifications in sync.
func updateArchiveState(
    _ isArchived: Bool,
    to calendar: CustomCalendar,
    store: CustomCalendarStore
) async throws -> CustomCalendar {
    var updatedCalendar = calendar
    updatedCalendar.isArchived = isArchived
    guard store.updateCalendar(updatedCalendar) else {
        throw ArchiveStateError.persistenceFailed
    }
    try await rescheduleNotifications(for: updatedCalendar, store: store)
    return updatedCalendar
}
