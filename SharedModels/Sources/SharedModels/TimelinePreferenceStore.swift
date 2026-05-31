import Foundation

public enum TimelinePreferenceStore {
    public static let appGroupId = SharedAppGroup.id
    public static let timelineModeKey = "timeline.mode.v1"

    public static var appGroupDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            assertionFailure("Unable to create app-group UserDefaults for \(appGroupId)")
            // Keep the app usable if the app group is unavailable, while surfacing the setup issue in debug builds.
            return .standard
        }

        return defaults
    }

    public static func storedMode(defaults: UserDefaults = appGroupDefaults) -> CalendarTimelineMode? {
        guard let rawValue = defaults.string(forKey: timelineModeKey) else { return nil }
        return CalendarTimelineMode(rawValue: rawValue)
    }

    public static func mode(rawValue: String?) -> CalendarTimelineMode {
        guard let rawValue, let mode = CalendarTimelineMode(rawValue: rawValue) else { return .your365 }
        return mode
    }

    public static func mode(defaults: UserDefaults = appGroupDefaults) -> CalendarTimelineMode {
        mode(rawValue: defaults.string(forKey: timelineModeKey))
    }

    public static func setMode(_ mode: CalendarTimelineMode, defaults: UserDefaults = appGroupDefaults) {
        defaults.set(mode.rawValue, forKey: timelineModeKey)
    }

    public static func setDefaultModeIfNeeded(defaults: UserDefaults = appGroupDefaults) {
        guard !hasStoredMode(defaults: defaults) else { return }
        setMode(.your365, defaults: defaults)
    }

    public static func hasStoredMode(defaults: UserDefaults = appGroupDefaults) -> Bool {
        storedMode(defaults: defaults) != nil
    }
}
