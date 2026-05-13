import Foundation
@testable import My_Year
import SharedModels
import Testing

struct StreakMilestonesTests {
    @Test func milestoneLookupMatchesRules() {
        #expect(StreakMilestones.milestone(for: 1) == nil)
        #expect(StreakMilestones.milestone(for: 2) == nil)
        #expect(StreakMilestones.milestone(for: 3) == 3)
        #expect(StreakMilestones.milestone(for: 4) == nil)
        #expect(StreakMilestones.milestone(for: 7) == 7)
        #expect(StreakMilestones.milestone(for: 13) == nil)
        #expect(StreakMilestones.milestone(for: 14) == 14)
        #expect(StreakMilestones.milestone(for: 30) == 30)
        #expect(StreakMilestones.milestone(for: 99) == nil)
        #expect(StreakMilestones.milestone(for: 100) == 100)
        #expect(StreakMilestones.milestone(for: 150) == nil)
        #expect(StreakMilestones.milestone(for: 200) == 200)
        #expect(StreakMilestones.milestone(for: 400) == 400)
        #expect(StreakMilestones.milestone(for: 300) == 300)
    }

    @Test func latestMilestoneAllowsDelayedCelebration() {
        #expect(StreakMilestones.latestMilestone(for: 1) == nil)
        #expect(StreakMilestones.latestMilestone(for: 2) == nil)
        #expect(StreakMilestones.latestMilestone(for: 4) == 3)
        #expect(StreakMilestones.latestMilestone(for: 13) == 7)
        #expect(StreakMilestones.latestMilestone(for: 29) == 14)
        #expect(StreakMilestones.latestMilestone(for: 100) == 100)
        #expect(StreakMilestones.latestMilestone(for: 199) == 100)
        #expect(StreakMilestones.latestMilestone(for: 250) == 200)
    }

    @Test func nextMilestoneFindsNextThreshold() {
        #expect(StreakMilestones.nextMilestone(after: 0) == 3)
        #expect(StreakMilestones.nextMilestone(after: 2) == 3)
        #expect(StreakMilestones.nextMilestone(after: 3) == 7)
        #expect(StreakMilestones.nextMilestone(after: 14) == 30)
        #expect(StreakMilestones.nextMilestone(after: 30) == 50)
        #expect(StreakMilestones.nextMilestone(after: 99) == 100)
        #expect(StreakMilestones.nextMilestone(after: 100) == 200)
        #expect(StreakMilestones.nextMilestone(after: 199) == 200)
        #expect(StreakMilestones.nextMilestone(after: 200) == 300)
    }
}

struct StreakMilestoneTrackerTests {
    @Test func trackerGatesMilestonesPerCalendar() throws {
        let suiteName = "streak.milestone.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let tracker = StreakMilestoneTracker(defaults: defaults)
        let calendarId = UUID()

        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 3) == 3)
        tracker.markCelebrated(calendarId: calendarId, milestone: 3)
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 3) == nil)
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 7) == 7)
    }

    @Test func trackerAllowsNextCheckToCelebrateMissedThreshold() throws {
        let suiteName = "streak.milestone.delay.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let tracker = StreakMilestoneTracker(defaults: defaults)
        let calendarId = UUID()

        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 4) == 3)
        tracker.markCelebrated(calendarId: calendarId, milestone: 3)
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 11) == 7)
    }

    @Test func trackerDoesNotRegressHigherRememberedState() throws {
        let suiteName = "streak.milestone.regression.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let tracker = StreakMilestoneTracker(defaults: defaults)
        let calendarId = UUID()

        tracker.markCelebrated(calendarId: calendarId, milestone: 7)
        tracker.markRemembered(calendarId: calendarId, milestone: 3)

        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 7) == nil)
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 14) == 14)
    }
}

struct ShowedUpMilestonesTests {
    @Test func scopedMilestoneLookupMatchesRules() {
        #expect(ShowedUpMilestones.milestone(for: 1) == nil)
        #expect(ShowedUpMilestones.milestone(for: 9) == nil)
        #expect(ShowedUpMilestones.milestone(for: 10) == 10)
        #expect(ShowedUpMilestones.milestone(for: 25) == 25)
        #expect(ShowedUpMilestones.milestone(for: 500) == 500)
        #expect(ShowedUpMilestones.milestone(for: 750) == nil)
        #expect(ShowedUpMilestones.milestone(for: 1000) == 1000)
        #expect(ShowedUpMilestones.milestone(for: 1500) == 1500)
        #expect(ShowedUpMilestones.milestone(for: 4, kind: .currentMonth) == nil)
        #expect(ShowedUpMilestones.milestone(for: 7, kind: .currentMonth) == 7)
        #expect(ShowedUpMilestones.milestone(for: 30, kind: .currentYear) == 30)
        #expect(ShowedUpMilestones.latestMilestone(for: 9) == nil)
        #expect(ShowedUpMilestones.latestMilestone(for: 234) == 100)
        #expect(ShowedUpMilestones.latestMilestone(for: 500) == 500)
        #expect(ShowedUpMilestones.latestMilestone(for: 999) == 500)
        #expect(ShowedUpMilestones.latestMilestone(for: 1000) == 1000)
        #expect(ShowedUpMilestones.latestMilestone(for: 17, kind: .currentMonth) == 14)
        #expect(ShowedUpMilestones.latestMilestone(for: 121, kind: .currentYear) == 120)
    }

    @Test func nextMilestoneFindsNextThreshold() {
        #expect(ShowedUpMilestones.nextMilestone(after: 0) == 10)
        #expect(ShowedUpMilestones.nextMilestone(after: 9) == 10)
        #expect(ShowedUpMilestones.nextMilestone(after: 10) == 25)
        #expect(ShowedUpMilestones.nextMilestone(after: 25) == 50)
        #expect(ShowedUpMilestones.nextMilestone(after: 500) == 1000)
        #expect(ShowedUpMilestones.nextMilestone(after: 999) == 1000)
        #expect(ShowedUpMilestones.nextMilestone(after: 1000) == 1500)
        #expect(ShowedUpMilestones.nextMilestone(after: 6, kind: .currentMonth) == 7)
        #expect(ShowedUpMilestones.nextMilestone(after: 250, kind: .currentYear) == 300)
        #expect(ShowedUpMilestones.nextMilestone(after: 28, kind: .currentMonth) == nil)
        #expect(ShowedUpMilestones.nextMilestone(after: 300, kind: .currentYear) == nil)
    }

    @Test func showedUpCountUsesSuccessAndCurrentPeriods() {
        let calendar = CustomCalendar(
            name: "Reading",
            color: "AccentColor",
            cadence: .daily,
            trackingType: .multipleDaily,
            trackingStartedAt: Date(),
            dailyTarget: 2,
            entries: [
                entryKey(year: 2026, month: 4, day: 2): CalendarEntry(
                    date: makeDate(year: 2026, month: 4, day: 2),
                    count: 2,
                    completed: true
                ),
                entryKey(year: 2026, month: 4, day: 3): CalendarEntry(
                    date: makeDate(year: 2026, month: 4, day: 3),
                    count: 1,
                    completed: false
                ),
                entryKey(year: 2026, month: 3, day: 20): CalendarEntry(
                    date: makeDate(year: 2026, month: 3, day: 20),
                    count: 3,
                    completed: true
                ),
                entryKey(year: 2025, month: 12, day: 31): CalendarEntry(
                    date: makeDate(year: 2025, month: 12, day: 31),
                    count: 2,
                    completed: true
                ),
            ]
        )

        let today = makeDate(year: 2026, month: 4, day: 21)

        #expect(ShowedUpMilestones.showedUpCount(for: calendar, kind: .allTime, today: today) == 4)
        #expect(ShowedUpMilestones.showedUpCount(for: calendar, kind: .currentMonth, today: today) == 2)
        #expect(ShowedUpMilestones.showedUpCount(for: calendar, kind: .currentYear, today: today) == 3)
        #expect(ShowedUpMilestones.periodKey(for: .currentMonth, today: today) == "2026-04")
        #expect(ShowedUpMilestones.periodKey(for: .currentYear, today: today) == "2026")
    }
}

struct ShowedUpMilestoneTrackerTests {
    @Test func trackerSeparatesKindsAndPeriods() throws {
        let suiteName = "showedup.milestone.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let tracker = ShowedUpMilestoneTracker(defaults: defaults)
        let calendarId = UUID()

        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 10,
                kind: .allTime,
                periodKey: "all"
            ) == 10
        )
        tracker.markCelebrated(
            calendarId: calendarId,
            milestone: 10,
            kind: .allTime,
            periodKey: "all"
        )

        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 10,
                kind: .allTime,
                periodKey: "all"
            ) == nil
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 7,
                kind: .currentMonth,
                periodKey: "2026-04"
            ) == 7
        )
        tracker.markCelebrated(
            calendarId: calendarId,
            milestone: 7,
            kind: .currentMonth,
            periodKey: "2026-04"
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 7,
                kind: .currentMonth,
                periodKey: "2026-05"
            ) == 7
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 30,
                kind: .currentYear,
                periodKey: "2026"
            ) == 30
        )
    }

    @Test func trackerDoesNotRegressHigherRememberedState() throws {
        let suiteName = "showedup.milestone.regression.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let tracker = ShowedUpMilestoneTracker(defaults: defaults)
        let calendarId = UUID()

        tracker.markCelebrated(
            calendarId: calendarId,
            milestone: 50,
            kind: .allTime,
            periodKey: "all"
        )
        tracker.markRemembered(
            calendarId: calendarId,
            milestone: 10,
            kind: .allTime,
            periodKey: "all"
        )

        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 51,
                kind: .allTime,
                periodKey: "all"
            ) == nil
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 500,
                kind: .allTime,
                periodKey: "all"
            ) == 500
        )
    }

    @Test func trackerMigratesLegacyAllTimeState() throws {
        let suiteName = "showedup.milestone.migration.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let calendarId = UUID()
        let legacyState = [calendarId.uuidString: 50]
        let legacyData = try JSONEncoder().encode(legacyState)
        defaults.set(legacyData, forKey: "showedUpMilestoneTracker.v1")

        let tracker = ShowedUpMilestoneTracker(defaults: defaults)

        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 51,
                kind: .allTime,
                periodKey: "all"
            ) == nil
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 250,
                kind: .allTime,
                periodKey: "all"
            ) == 250
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 500,
                kind: .allTime,
                periodKey: "all"
            ) == 500
        )
    }

    @Test func trackerMergesLegacyAndCurrentState() throws {
        let suiteName = "showedup.milestone.merge.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let calendarId = UUID()
        let legacyData = try JSONEncoder().encode([calendarId.uuidString: 50])
        let currentData = try JSONEncoder().encode([
            "\(ShowedUpMilestoneKind.currentMonth.rawValue)|2026-04|\(calendarId.uuidString)": 7,
        ])
        defaults.set(legacyData, forKey: "showedUpMilestoneTracker.v1")
        defaults.set(currentData, forKey: "showedUpMilestoneTracker.v2")

        let tracker = ShowedUpMilestoneTracker(defaults: defaults)

        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 51,
                kind: .allTime,
                periodKey: "all"
            ) == nil
        )
        #expect(
            tracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 10,
                kind: .currentMonth,
                periodKey: "2026-04"
            ) == 10
        )
    }
}

struct MilestoneCelebrationSettingsTests {
    @Test func defaultValuesAreReturnedWhenUnset() throws {
        let suiteName = "milestone.settings.default.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let settings = MilestoneCelebrationSettings(defaults: defaults)

        #expect(settings.milestoneCelebrationsEnabled)
        #expect(settings.streakMilestoneCelebrationsEnabled)
        #expect(settings.showedUpMilestoneCelebrationsEnabled)
        #expect(settings.recapMilestoneCelebrationsEnabled == false)
    }

    @Test func storedValuesOverrideDefaults() throws {
        let suiteName = "milestone.settings.override.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(false, forKey: AppStorageKeys.milestoneCelebrationsEnabled)
        defaults.set(false, forKey: AppStorageKeys.streakMilestoneCelebrationsEnabled)
        defaults.set(false, forKey: AppStorageKeys.showedUpMilestoneCelebrationsEnabled)
        defaults.set(true, forKey: AppStorageKeys.recapMilestoneCelebrationsEnabled)

        let settings = MilestoneCelebrationSettings(defaults: defaults)

        #expect(settings.milestoneCelebrationsEnabled == false)
        #expect(settings.streakMilestoneCelebrationsEnabled == false)
        #expect(settings.showedUpMilestoneCelebrationsEnabled == false)
        #expect(settings.recapMilestoneCelebrationsEnabled)
    }
}

struct MilestoneCelebrationPolicyTests {
    @Test func disabledMasterSilentlyRemembersStreakMilestones() throws {
        let suiteName = "milestone.policy.master.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(false, forKey: AppStorageKeys.milestoneCelebrationsEnabled)

        let policy = MilestoneCelebrationPolicy(
            settings: MilestoneCelebrationSettings(defaults: defaults),
            streakTracker: StreakMilestoneTracker(defaults: defaults),
            showedUpTracker: ShowedUpMilestoneTracker(defaults: defaults)
        )
        let calendarId = UUID()

        let decision = policy.decisionForStreakMilestone(calendarId: calendarId, streak: 3)
        #expect(decision?.milestone == 3)
        #expect(decision?.shouldPresent == false)
        #expect(policy.decisionForStreakMilestone(calendarId: calendarId, streak: 3) == nil)
    }

    @Test func disabledCategorySilentlyRemembersShowedUpMilestones() throws {
        let suiteName = "milestone.policy.category.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(false, forKey: AppStorageKeys.recapMilestoneCelebrationsEnabled)

        let policy = MilestoneCelebrationPolicy(
            settings: MilestoneCelebrationSettings(defaults: defaults),
            streakTracker: StreakMilestoneTracker(defaults: defaults),
            showedUpTracker: ShowedUpMilestoneTracker(defaults: defaults)
        )
        let calendarId = UUID()

        let periodKey = "2026-04"
        let decision = policy.decisionForShowedUpMilestone(
            calendarId: calendarId,
            showedUpCount: 10,
            kind: .currentMonth,
            periodKey: periodKey
        )
        #expect(decision?.milestone == 10)
        #expect(decision?.shouldPresent == false)
        #expect(
            policy.decisionForShowedUpMilestone(
                calendarId: calendarId,
                showedUpCount: 10,
                kind: .currentMonth,
                periodKey: periodKey
            ) == nil
        )
    }

    @Test func enabledAllTimeMilestonesStillPresent() throws {
        let suiteName = "milestone.policy.enabled.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError("Unable to create UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let policy = MilestoneCelebrationPolicy(
            settings: MilestoneCelebrationSettings(defaults: defaults),
            streakTracker: StreakMilestoneTracker(defaults: defaults),
            showedUpTracker: ShowedUpMilestoneTracker(defaults: defaults)
        )
        let calendarId = UUID()

        let decision = policy.decisionForShowedUpMilestone(
            calendarId: calendarId,
            showedUpCount: 10,
            kind: .allTime,
            periodKey: "all"
        )
        #expect(decision?.milestone == 10)
        #expect(decision?.shouldPresent == true)
        #expect(
            policy.decisionForShowedUpMilestone(
                calendarId: calendarId,
                showedUpCount: 10,
                kind: .allTime,
                periodKey: "all"
            ) == nil
        )
    }
}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
    return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
}

private func entryKey(year: Int, month: Int, day: Int) -> String {
    DayKeyFormatter.shared.string(from: makeDate(year: year, month: month, day: day))
}

struct TestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
