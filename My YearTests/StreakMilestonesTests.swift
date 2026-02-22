import Foundation
@testable import My_Year
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
}

struct TestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
