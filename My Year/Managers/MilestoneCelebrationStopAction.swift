import Foundation

final class MilestoneCelebrationStopAction {
    private let settings: MilestoneCelebrationSettings
    private let streakTracker: StreakMilestoneTracker
    private let showedUpTracker: ShowedUpMilestoneTracker

    init(
        settings: MilestoneCelebrationSettings = .init(),
        streakTracker: StreakMilestoneTracker = .shared,
        showedUpTracker: ShowedUpMilestoneTracker = .shared
    ) {
        self.settings = settings
        self.streakTracker = streakTracker
        self.showedUpTracker = showedUpTracker
    }

    func stopShowing(
        kind: MilestoneKind,
        calendarId: UUID,
        milestone: Int,
        referenceDate: Date = Date()
    ) {
        disableCelebration(for: kind)
        rememberDisplayedMilestone(
            kind: kind,
            calendarId: calendarId,
            milestone: milestone,
            referenceDate: referenceDate
        )
    }

    private func disableCelebration(for kind: MilestoneKind) {
        switch kind {
        case .streak:
            settings.streakMilestoneCelebrationsEnabled = false
        case .showedUp:
            settings.showedUpMilestoneCelebrationsEnabled = false
        case .showedUpMonth, .showedUpYear:
            settings.recapMilestoneCelebrationsEnabled = false
        }
    }

    private func rememberDisplayedMilestone(
        kind: MilestoneKind,
        calendarId: UUID,
        milestone: Int,
        referenceDate: Date
    ) {
        switch kind {
        case .streak:
            streakTracker.markRemembered(calendarId: calendarId, milestone: milestone)
        case .showedUp:
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .allTime,
                periodKey: ShowedUpMilestones.periodKey(for: .allTime, today: referenceDate)
            )
        case .showedUpMonth:
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .currentMonth,
                periodKey: ShowedUpMilestones.periodKey(for: .currentMonth, today: referenceDate)
            )
        case .showedUpYear:
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .currentYear,
                periodKey: ShowedUpMilestones.periodKey(for: .currentYear, today: referenceDate)
            )
        }
    }
}
