enum AnalyticsEvent: String, CaseIterable {
  case appOpened = "app_opened"
  case onboardingStarted = "onboarding_started"
  case onboardingCompleted = "onboarding_completed"

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

  case paywallViewed = "paywall_viewed"
  case shareSheetViewed = "share_sheet_viewed"
}
