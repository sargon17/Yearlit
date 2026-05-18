enum AnalyticsEvent: String, CaseIterable {
  case appOpened = "app_opened"
  case onboardingStarted = "onboarding_started"
  case onboardingCompleted = "onboarding_completed"
  case onboardingStepViewed = "onboarding_step_viewed"
  case onboardingActionPerformed = "onboarding_action_performed"

  case calendarCreated = "calendar_created"
  case calendarArchived = "calendar_archived"
  case calendarUnarchived = "calendar_unarchived"
  case checkinCompleted = "checkin_completed"
  case firstCheckinCompleted = "first_checkin_completed"
  case checkinRemoved = "checkin_removed"
  case periodCompleted = "period_completed"
  case periodUncompleted = "period_uncompleted"

  case moodLogged = "mood_logged"
  case moodTrackingEnabledChanged = "mood_tracking_enabled_changed"
  case recapViewEnabledChanged = "recap_view_enabled_changed"
  case milestoneCelebrationsEnabledChanged = "milestone_celebrations_enabled_changed"
  case streakMilestoneCelebrationsEnabledChanged = "streak_milestone_celebrations_enabled_changed"
  case showedUpMilestoneCelebrationsEnabledChanged = "showed_up_milestone_celebrations_enabled_changed"
  case recapMilestoneCelebrationsEnabledChanged = "recap_milestone_celebrations_enabled_changed"
  case recapViewViewed = "recap_view_viewed"
  case calendarsOverviewViewed = "calendars_overview_viewed"

  case widgetTimelineLoaded = "widget_timeline_loaded"
  case widgetOpenedApp = "widget_opened_app"
  case widgetQuickAddPerformed = "widget_quick_add_performed"
  case widgetQuickAddOpened = "widget_quick_add_opened"

  case paywallViewed = "paywall_viewed"
  case shareSheetViewed = "share_sheet_viewed"
}

enum PaywallTrigger: String, CaseIterable {
  case onboarding
  case calendarLimit = "calendar_limit"
  case shareGate = "share_gate"
  case statsGate = "stats_gate"
  case notificationGate = "notification_gate"
  case settingsSupport = "settings_support"
  case unknown
}

enum ShareType: String, CaseIterable {
  case calendar
  case recap
  case unknown
}

enum OnboardingAction: String, CaseIterable {
  case identityCompleted = "identity_completed"
  case tinyHabitCreated = "tiny_habit_created"
  case firstDotMarked = "first_dot_marked"
  case reviewRequested = "review_requested"
  case reviewSkipped = "review_skipped"
  case notificationsRequested = "notifications_requested"
  case notificationsSkipped = "notifications_skipped"
  case readyContinued = "ready_continued"
  case paywallBoundaryReached = "paywall_boundary_reached"
  case paywallClosed = "paywall_closed"
}

enum OnboardingStepCatalog {
  static let stepIDs: [String] = OnboardingStep.allCases.map(\.rawValue)
}

enum AnalyticsCatalog {
  static let standardPropertyKeys: [String] = [
    "days_since_install",
    "app_version",
    "build_number",
    "app_locale_language",
    "is_premium",
    "premium_status_known",
    "mood_tracking_enabled",
    "recap_view_enabled",
    "milestone_celebrations_enabled",
    "streak_milestone_celebrations_enabled",
    "showed_up_milestone_celebrations_enabled",
    "recap_milestone_celebrations_enabled",
    "calendar_count",
    "active_calendar_count",
    "archived_calendar_count",
    "daily_calendar_count",
    "weekly_calendar_count",
    "binary_calendar_count",
    "counter_calendar_count",
    "target_calendar_count",
    "calendar_with_reminder_count",
    "has_reminders_enabled",
    "has_completed_first_checkin",
    "has_completed_first_period"
  ]

  static let forbiddenSensitivePropertyKeys: [String] = [
    "calendar_name",
    "calendar_names",
    "habit_name",
    "habit_names",
    "goal_text",
    "journal_note",
    "journal_notes",
    "mood_note",
    "mood_note_text",
    "notification_text"
  ]

  static let forbiddenSensitiveContentCategories: [String] = [
    "calendar names",
    "habit names",
    "goal text",
    "journal notes",
    "mood note text",
    "notification text",
    "any other user-entered sensitive content"
  ]
}
