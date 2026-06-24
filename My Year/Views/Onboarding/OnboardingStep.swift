enum OnboardingStep: String, CaseIterable, Identifiable {
  case emotionalHook = "emotional_hook"
  case appExplanation = "app_explanation"
  case identityCommitment = "identity_commitment"
  case tinyHabitSelection = "tiny_habit_selection"
  case firstDot = "first_dot"
  case notificationPermission = "notification_permission"
  case readyWidgets = "ready_widgets"
  case paywall = "paywall"

  var id: String { rawValue }
}
