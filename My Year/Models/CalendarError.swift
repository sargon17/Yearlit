import Foundation

enum CalendarError: LocalizedError, Identifiable {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)
  case appleHealthSyncFailed(Error)

  var id: String {
    localizedDescription
  }

  var title: String {
    switch self {
    case .invalidName:
      return String(localized: "Invalid Name")
    case .notificationPermissionDenied:
      return String(localized: "Notification Permission Denied")
    case .notificationSchedulingFailed:
      return String(localized: "Notification Error")
    case .errorAddingEntry:
      return String(localized: "Entry Error")
    case .appleHealthSyncFailed:
      return String(localized: "Apple Health Error")
    }
  }

  var message: String {
    errorDescription ?? String(localized: "An unknown error occurred.")
  }

  var errorDescription: String? {
    switch self {
    case .invalidName:
      return String(localized: "Please enter a valid name (1-50 characters)")
    case .notificationPermissionDenied:
      return String(localized: "Please enable notifications in Settings to receive reminders.")
    case .notificationSchedulingFailed(let error):
      return String(localized: "Failed to schedule notification: \(error.localizedDescription)")
    case .errorAddingEntry(let error):
      return String(localized: "Failed to add entry: \(error.localizedDescription)")
    case .appleHealthSyncFailed(let error):
      return String(localized: "Failed to read Apple Health steps: \(error.localizedDescription)")
    }
  }
}
