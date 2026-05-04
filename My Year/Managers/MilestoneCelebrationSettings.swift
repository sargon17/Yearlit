import Foundation

final class MilestoneCelebrationSettings {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var milestoneCelebrationsEnabled: Bool {
        get { bool(forKey: AppStorageKeys.milestoneCelebrationsEnabled, defaultValue: true) }
        set { defaults.set(newValue, forKey: AppStorageKeys.milestoneCelebrationsEnabled) }
    }

    var streakMilestoneCelebrationsEnabled: Bool {
        get { bool(forKey: AppStorageKeys.streakMilestoneCelebrationsEnabled, defaultValue: true) }
        set { defaults.set(newValue, forKey: AppStorageKeys.streakMilestoneCelebrationsEnabled) }
    }

    var showedUpMilestoneCelebrationsEnabled: Bool {
        get {
            bool(
                forKey: AppStorageKeys.showedUpMilestoneCelebrationsEnabled,
                defaultValue: true
            )
        }
        set { defaults.set(newValue, forKey: AppStorageKeys.showedUpMilestoneCelebrationsEnabled) }
    }

    var recapMilestoneCelebrationsEnabled: Bool {
        get { bool(forKey: AppStorageKeys.recapMilestoneCelebrationsEnabled, defaultValue: false) }
        set { defaults.set(newValue, forKey: AppStorageKeys.recapMilestoneCelebrationsEnabled) }
    }

    var shouldPresentStreakCelebration: Bool {
        milestoneCelebrationsEnabled && streakMilestoneCelebrationsEnabled
    }

    func shouldPresentShowedUpCelebration(for kind: ShowedUpMilestoneKind) -> Bool {
        guard milestoneCelebrationsEnabled else { return false }

        switch kind {
        case .allTime:
            return showedUpMilestoneCelebrationsEnabled
        case .currentMonth, .currentYear:
            return recapMilestoneCelebrationsEnabled
        }
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}
