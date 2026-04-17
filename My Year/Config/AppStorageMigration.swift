import Foundation

enum AppStorageMigration {
  static func run(defaults: UserDefaults = .standard) {
    migrateMoodTrackingEnabled(defaults: defaults)
  }

  private static func migrateMoodTrackingEnabled(defaults: UserDefaults) {
    let moodTrackingKey = AppStorageKeys.isMoodTrackingEnabled

    guard defaults.object(forKey: moodTrackingKey) == nil else { return }
    guard defaults.object(forKey: AppStorageKeys.onboardingSeenV1) != nil else { return }

    defaults.set(true, forKey: moodTrackingKey)
  }
}
