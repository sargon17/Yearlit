import Foundation
@testable import My_Year
import SharedModels
import Testing

struct StreakMilestonesTests {
    @Test func milestoneLookupMatchesRules() {
        #expect(StreakMilestones.milestone(for: 1) == 1)
        #expect(StreakMilestones.milestone(for: 2) == 2)
        #expect(StreakMilestones.milestone(for: 3) == 3)
        #expect(StreakMilestones.milestone(for: 4) == nil)
        #expect(StreakMilestones.milestone(for: 5) == 5)
        #expect(StreakMilestones.milestone(for: 25) == 25)
        #expect(StreakMilestones.milestone(for: 30) == 30)
        #expect(StreakMilestones.milestone(for: 40) == 40)
        #expect(StreakMilestones.milestone(for: 70) == 70)
        #expect(StreakMilestones.milestone(for: 75) == nil)
        #expect(StreakMilestones.milestone(for: 80) == 80)
    }

    @Test func latestMilestoneAllowsDelayedCelebration() {
        #expect(StreakMilestones.latestMilestone(for: 4) == 3)
        #expect(StreakMilestones.latestMilestone(for: 11) == 10)
    }

    @Test func nextMilestoneFindsNextThreshold() {
        #expect(StreakMilestones.nextMilestone(after: 0) == 1)
        #expect(StreakMilestones.nextMilestone(after: 3) == 5)
        #expect(StreakMilestones.nextMilestone(after: 30) == 40)
        #expect(StreakMilestones.nextMilestone(after: 44) == 50)
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
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 5) == 5)
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
        #expect(tracker.milestoneToCelebrate(calendarId: calendarId, streak: 11) == 10)
    }
}

struct ShowedUpMilestonesTests {
    @Test func scopedMilestoneLookupMatchesRules() {
        #expect(ShowedUpMilestones.milestone(for: 5) == 5)
        #expect(ShowedUpMilestones.milestone(for: 200) == 200)
        #expect(ShowedUpMilestones.milestone(for: 4, kind: .currentMonth) == nil)
        #expect(ShowedUpMilestones.milestone(for: 7, kind: .currentMonth) == 7)
        #expect(ShowedUpMilestones.milestone(for: 30, kind: .currentYear) == 30)
        #expect(ShowedUpMilestones.latestMilestone(for: 234) == 200)
        #expect(ShowedUpMilestones.latestMilestone(for: 17, kind: .currentMonth) == 14)
        #expect(ShowedUpMilestones.latestMilestone(for: 121, kind: .currentYear) == 120)
    }

    @Test func nextMilestoneFindsNextThreshold() {
        #expect(ShowedUpMilestones.nextMilestone(after: 0) == 5)
        #expect(ShowedUpMilestones.nextMilestone(after: 18) == 20)
        #expect(ShowedUpMilestones.nextMilestone(after: 151) == 200)
        #expect(ShowedUpMilestones.nextMilestone(after: 205) == 250)
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
                showedUpCount: 11,
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
                showedUpCount: 11,
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
                showedUpCount: 75,
                kind: .allTime,
                periodKey: "all"
            ) == 75
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
