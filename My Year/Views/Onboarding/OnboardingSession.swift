import Foundation

struct OnboardingSession {
  var selectedMotivation: OnboardingMotivation?
  var displayName = ""
  var selectedIdentityCommitments: [IdentityCommitment] = []
  var selectedTinyHabitName: String?
  var selectedHabitColor = "qs-orange"
  var tinyHabitCalendarId: UUID?
  var didCompleteFirstDot = false
  var didRequestNotifications = false

  var trimmedDisplayName: String {
    displayName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var hasDisplayName: Bool {
    !trimmedDisplayName.isEmpty
  }

  mutating func toggleIdentityCommitment(_ commitment: IdentityCommitment) {
    if let index = selectedIdentityCommitments.firstIndex(of: commitment) {
      selectedIdentityCommitments.remove(at: index)
      return
    }

    selectedIdentityCommitments.append(commitment)
  }
}
