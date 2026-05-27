import Foundation
import RevenueCat
import SharedModels

@MainActor
final class AnalyticsState {
  static let shared = AnalyticsState()

  private let defaults: UserDefaults
  private let installDateKey = "analytics.install_date"
  private let distinctIDKey = "analytics.distinct_id"
  private let firstCheckinCompletedKey = "analytics.has_completed_first_checkin"
  private let firstPeriodCompletedKey = "analytics.has_completed_first_period"

  private(set) var isPremiumUser = false
  private(set) var premiumStatusKnown = false

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var distinctID: String {
    if let existing = defaults.string(forKey: distinctIDKey), !existing.isEmpty {
      return existing
    }

    let id = UUID().uuidString
    defaults.set(id, forKey: distinctIDKey)
    return id
  }

  var installDate: Date {
    if let existing = defaults.object(forKey: installDateKey) as? Date {
      return existing
    }

    let date = Date()
    defaults.set(date, forKey: installDateKey)
    return date
  }

  var daysSinceInstall: Int {
    let start = Calendar.current.startOfDay(for: installDate)
    let today = Calendar.current.startOfDay(for: Date())
    return Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
  }

  func updatePremiumStatus(customerInfo: CustomerInfo?) {
    premiumStatusKnown = customerInfo != nil
    isPremiumUser = isPremium(customerInfo: customerInfo)
    if customerInfo != nil {
      DailyWallpaperSettingsStore.setCachedPremiumAccess(isPremiumUser, defaults: defaults)
    }
    Analytics.shared.updatePersonProperties()
  }

  var hasCompletedFirstCheckin: Bool {
    defaults.bool(forKey: firstCheckinCompletedKey)
  }

  func markFirstCheckinCompleted() {
    defaults.set(true, forKey: firstCheckinCompletedKey)
  }

  var hasCompletedFirstPeriod: Bool {
    defaults.bool(forKey: firstPeriodCompletedKey)
  }

  func markFirstPeriodCompleted() {
    defaults.set(true, forKey: firstPeriodCompletedKey)
  }

  func standardProperties() -> [String: AnalyticsPropertyValue] {
    let snapshot = CustomCalendarStore.shared.snapshot
    let activeCalendars = snapshot.activeCalendars

    return [
      "days_since_install": .int(daysSinceInstall),
      "app_version": .string(
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"),
      "build_number": .string(
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"),
      "app_locale_language": .string(Locale.current.language.languageCode?.identifier ?? "unknown"),
      "is_premium": .bool(isPremiumUser),
      "premium_status_known": .bool(premiumStatusKnown),
      "mood_tracking_enabled": .bool(defaults.bool(forKey: AppStorageKeys.isMoodTrackingEnabled)),
      "recap_view_enabled": .bool(defaults.bool(forKey: AppStorageKeys.isRecapViewEnabled)),
      "milestone_celebrations_enabled": .bool(
        defaults.object(forKey: AppStorageKeys.milestoneCelebrationsEnabled) as? Bool ?? true),
      "streak_milestone_celebrations_enabled": .bool(
        defaults.object(forKey: AppStorageKeys.streakMilestoneCelebrationsEnabled) as? Bool ?? true),
      "showed_up_milestone_celebrations_enabled": .bool(
        defaults.object(forKey: AppStorageKeys.showedUpMilestoneCelebrationsEnabled) as? Bool ?? true),
      "recap_milestone_celebrations_enabled": .bool(
        defaults.bool(forKey: AppStorageKeys.recapMilestoneCelebrationsEnabled)),
      "calendar_count": .int(snapshot.calendars.count),
      "active_calendar_count": .int(snapshot.activeCalendars.count),
      "archived_calendar_count": .int(snapshot.archivedCalendars.count),
      "daily_calendar_count": .int(activeCalendars.filter { $0.cadence == .daily }.count),
      "weekly_calendar_count": .int(activeCalendars.filter { $0.cadence == .weekly }.count),
      "binary_calendar_count": .int(activeCalendars.filter { $0.trackingType == .binary }.count),
      "counter_calendar_count": .int(activeCalendars.filter { $0.trackingType == .counter }.count),
      "target_calendar_count": .int(activeCalendars.filter { $0.trackingType == .multipleDaily }.count),
      "calendar_with_reminder_count": .int(activeCalendars.filter(\.recurringReminderEnabled).count),
      "has_reminders_enabled": .bool(activeCalendars.contains(where: \.recurringReminderEnabled)),
      "has_completed_first_checkin": .bool(hasCompletedFirstCheckin),
      "has_completed_first_period": .bool(hasCompletedFirstPeriod)
    ]
  }
}
