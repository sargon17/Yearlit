import Foundation

enum CalendarError: LocalizedError, Identifiable {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)

  var id: String {
    localizedDescription
  }

  var title: String {
    switch self {
    case .invalidName:
      return "Invalid Name"
    case .notificationPermissionDenied:
      return "Notification Permission Denied"
    case .notificationSchedulingFailed:
      return "Notification Error"
    case .errorAddingEntry:
      return "Entry Error"
    }
  }

  var message: String {
    errorDescription ?? "An unknown error occurred."
  }

  var errorDescription: String? {
    switch self {
    case .invalidName:
      return "Please enter a valid name (1-50 characters)"
    case .notificationPermissionDenied:
      return "Please enable notifications in Settings to receive reminders."
    case .notificationSchedulingFailed(let error):
      return "Failed to schedule notification: \(error.localizedDescription)"
    case .errorAddingEntry(let error):
      return "Failed to add entry: \(error.localizedDescription)"
    }
  }
}
