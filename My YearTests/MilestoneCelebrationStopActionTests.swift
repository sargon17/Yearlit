import Foundation
@testable import My_Year
import Testing

struct MilestoneCelebrationStopActionTests {
    @Test func stoppingStreakCelebrationDisablesOnlyStreakCategoryAndRemembersMilestone() throws {
        let fixture = makeFixture()
        defer { tearDownFixture(fixture) }

        let settings = MilestoneCelebrationSettings(defaults: fixture.defaults)
        let streakTracker = StreakMilestoneTracker(defaults: fixture.defaults)
        let stopAction = MilestoneCelebrationStopAction(
            settings: settings,
            streakTracker: streakTracker,
            showedUpTracker: ShowedUpMilestoneTracker(defaults: fixture.defaults)
        )
        let calendarId = UUID()
        settings.showedUpMilestoneCelebrationsEnabled = false
        settings.recapMilestoneCelebrationsEnabled = true

        stopAction.stopShowing(
            kind: .streak,
            calendarId: calendarId,
            milestone: 14,
            showedUpPeriodKey: nil
        )

        #expect(settings.milestoneCelebrationsEnabled)
        #expect(settings.streakMilestoneCelebrationsEnabled == false)
        #expect(settings.showedUpMilestoneCelebrationsEnabled == false)
        #expect(settings.recapMilestoneCelebrationsEnabled)
        #expect(streakTracker.milestoneToCelebrate(calendarId: calendarId, streak: 14) == nil)
    }

    @Test func stoppingRecapCelebrationUsesPresentedPeriodKey() throws {
        let fixture = makeFixture()
        defer { tearDownFixture(fixture) }

        let settings = MilestoneCelebrationSettings(defaults: fixture.defaults)
        let showedUpTracker = ShowedUpMilestoneTracker(defaults: fixture.defaults)
        let stopAction = MilestoneCelebrationStopAction(
            settings: settings,
            streakTracker: StreakMilestoneTracker(defaults: fixture.defaults),
            showedUpTracker: showedUpTracker
        )
        let calendarId = UUID()
        let referenceDate = makeDate(year: 2026, month: 4, day: 21)
        let periodKey = ShowedUpMilestones.periodKey(for: .currentMonth, today: referenceDate)
        settings.streakMilestoneCelebrationsEnabled = false
        settings.showedUpMilestoneCelebrationsEnabled = false
        settings.recapMilestoneCelebrationsEnabled = true

        stopAction.stopShowing(
            kind: .showedUpMonth,
            calendarId: calendarId,
            milestone: 7,
            showedUpPeriodKey: periodKey
        )

        #expect(settings.milestoneCelebrationsEnabled)
        #expect(settings.streakMilestoneCelebrationsEnabled == false)
        #expect(settings.showedUpMilestoneCelebrationsEnabled == false)
        #expect(settings.recapMilestoneCelebrationsEnabled == false)
        #expect(
            showedUpTracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 7,
                kind: .currentMonth,
                periodKey: periodKey
            ) == nil
        )
        #expect(
            showedUpTracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 7,
                kind: .currentMonth,
                periodKey: "2026-05"
            ) == 7
        )
    }

    @Test func stoppingYearlyRecapCelebrationUsesPresentedPeriodKey() throws {
        let fixture = makeFixture()
        defer { tearDownFixture(fixture) }

        let settings = MilestoneCelebrationSettings(defaults: fixture.defaults)
        let showedUpTracker = ShowedUpMilestoneTracker(defaults: fixture.defaults)
        let stopAction = MilestoneCelebrationStopAction(
            settings: settings,
            streakTracker: StreakMilestoneTracker(defaults: fixture.defaults),
            showedUpTracker: showedUpTracker
        )
        let calendarId = UUID()
        let periodKey = "2026"
        settings.streakMilestoneCelebrationsEnabled = false
        settings.showedUpMilestoneCelebrationsEnabled = false
        settings.recapMilestoneCelebrationsEnabled = true

        stopAction.stopShowing(
            kind: .showedUpYear,
            calendarId: calendarId,
            milestone: 30,
            showedUpPeriodKey: periodKey
        )

        #expect(settings.milestoneCelebrationsEnabled)
        #expect(settings.recapMilestoneCelebrationsEnabled == false)
        #expect(
            showedUpTracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 30,
                kind: .currentYear,
                periodKey: periodKey
            ) == nil
        )
        #expect(
            showedUpTracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: 30,
                kind: .currentYear,
                periodKey: "2027"
            ) == 30
        )
    }

    private func makeFixture() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "MilestoneCelebrationStopActionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }

    private func tearDownFixture(_ fixture: (suiteName: String, defaults: UserDefaults)) {
        fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
