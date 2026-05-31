import Foundation
@testable import SharedModels
import Testing

struct TimelinePreferenceStoreTests {
    @Test func storedModeIsNilBeforeWriteAndDefaultsToYour365() {
        let defaults = makeDefaults()
        defer { tearDownDefaults(defaults) }

        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == nil)
        #expect(TimelinePreferenceStore.mode(defaults: defaults) == .your365)
        #expect(!TimelinePreferenceStore.hasStoredMode(defaults: defaults))
    }

    @Test func writesAndReadsBothModes() {
        let defaults = makeDefaults()
        defer { tearDownDefaults(defaults) }

        TimelinePreferenceStore.setMode(.your365, defaults: defaults)
        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == .your365)
        #expect(TimelinePreferenceStore.mode(defaults: defaults) == .your365)
        #expect(TimelinePreferenceStore.hasStoredMode(defaults: defaults))

        TimelinePreferenceStore.setMode(.calendarYear, defaults: defaults)
        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == .calendarYear)
        #expect(TimelinePreferenceStore.mode(defaults: defaults) == .calendarYear)
    }

    @Test func defaultModeWriteIsOnlyForMissingPreference() {
        let defaults = makeDefaults()
        defer { tearDownDefaults(defaults) }

        TimelinePreferenceStore.setDefaultModeIfNeeded(defaults: defaults)
        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == .your365)

        TimelinePreferenceStore.setMode(.calendarYear, defaults: defaults)
        TimelinePreferenceStore.setDefaultModeIfNeeded(defaults: defaults)
        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == .calendarYear)
    }

    @Test func rawValueParsingDefaultsToYour365ForMissingOrInvalidValues() {
        #expect(TimelinePreferenceStore.mode(rawValue: nil) == .your365)
        #expect(TimelinePreferenceStore.mode(rawValue: "") == .your365)
        #expect(TimelinePreferenceStore.mode(rawValue: "invalid") == .your365)
        #expect(
            TimelinePreferenceStore.mode(rawValue: CalendarTimelineMode.calendarYear.rawValue) == .calendarYear
        )
    }

    @Test func invalidStoredModeDefaultsToYour365AndDoesNotCountAsStored() {
        let defaults = makeDefaults()
        defer { tearDownDefaults(defaults) }

        defaults.set("invalid", forKey: TimelinePreferenceStore.timelineModeKey)

        #expect(TimelinePreferenceStore.storedMode(defaults: defaults) == nil)
        #expect(TimelinePreferenceStore.mode(defaults: defaults) == .your365)
        #expect(!TimelinePreferenceStore.hasStoredMode(defaults: defaults))
    }

    @Test func weeklyCadenceAlwaysUsesCalendarYear() {
        #expect(CalendarTimelineMode.your365.effectiveMode(for: .weekly) == .calendarYear)
        #expect(CalendarTimelineMode.calendarYear.effectiveMode(for: .weekly) == .calendarYear)
        #expect(CalendarTimelineMode.your365.effectiveMode(for: .daily) == .your365)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "TimelinePreferenceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(suiteName, forKey: "__suiteName")
        return defaults
    }

    private func tearDownDefaults(_ defaults: UserDefaults) {
        guard let suiteName = defaults.string(forKey: "__suiteName") else { return }
        defaults.removePersistentDomain(forName: suiteName)
    }
}
