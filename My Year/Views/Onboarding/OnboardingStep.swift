enum OnboardingStep: String, CaseIterable, Identifiable {
  case emotionalHook = "emotional_hook"
  case appExplanation = "app_explanation"
  case motivation = "motivation"
  case identityCommitment = "identity_commitment"
  case name = "name"
  case tinyHabitSelection = "tiny_habit_selection"
  case firstDot = "first_dot"
  case whyThisWorks = "why_this_works"
  case notificationPermission = "notification_permission"
  case readyWidgets = "ready_widgets"
  case founderNote = "founder_note"
  case socialProof = "social_proof"
  case paywall = "paywall"

  var id: String { rawValue }
}
