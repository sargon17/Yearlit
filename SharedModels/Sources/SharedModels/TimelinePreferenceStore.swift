import Foundation

public enum TimelinePreferenceStore {
    public static let appGroupId = "group.sargon17.My-Year"
    public static let timelineModeKey = "timeline.mode.v1"

    public static var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
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

    public static func hasStoredMode(defaults: UserDefaults = appGroupDefaults) -> Bool {
        storedMode(defaults: defaults) != nil
    }
}
