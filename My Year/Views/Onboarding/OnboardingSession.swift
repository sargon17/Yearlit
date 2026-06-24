import Foundation

struct OnboardingSession {
  var selectedIdentityCommitments: [IdentityCommitment] = []
  var selectedTinyHabitName: String?
  var tinyHabitCalendarId: UUID?
  var didCompleteFirstDot = false
  var didRequestNotifications = false

  mutating func toggleIdentityCommitment(_ commitment: IdentityCommitment) {
    if let index = selectedIdentityCommitments.firstIndex(of: commitment) {
      selectedIdentityCommitments.remove(at: index)
      return
    }

    selectedIdentityCommitments.append(commitment)
  }
}
