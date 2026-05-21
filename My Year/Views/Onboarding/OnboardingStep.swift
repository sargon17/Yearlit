enum OnboardingStep: String, CaseIterable, Identifiable {
  case emotionalHook = "emotional_hook"
  case appExplanation = "app_explanation"
  case identityCommitment = "identity_commitment"
  case tinyHabitSelection = "tiny_habit_selection"
  case firstDot = "first_dot"
  case preReviewGate = "pre_review_gate"
  case reviewRequest = "review_request"
  case notificationPermission = "notification_permission"
  case readyWidgets = "ready_widgets"
  case paywall = "paywall"

  var id: String { rawValue }
}
