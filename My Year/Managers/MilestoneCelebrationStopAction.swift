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
        showedUpPeriodKey: String?
    ) {
        disableCelebration(for: kind)
        rememberDisplayedMilestone(
            kind: kind,
            calendarId: calendarId,
            milestone: milestone,
            showedUpPeriodKey: showedUpPeriodKey
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
        showedUpPeriodKey: String?
    ) {
        switch kind {
        case .streak:
            streakTracker.markRemembered(calendarId: calendarId, milestone: milestone)
        case .showedUp:
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .allTime,
                periodKey: showedUpPeriodKey ?? ShowedUpMilestones.periodKey(for: .allTime)
            )
        case .showedUpMonth:
            guard let showedUpPeriodKey else { return }
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .currentMonth,
                periodKey: showedUpPeriodKey
            )
        case .showedUpYear:
            guard let showedUpPeriodKey else { return }
            showedUpTracker.markRemembered(
                calendarId: calendarId,
                milestone: milestone,
                kind: .currentYear,
                periodKey: showedUpPeriodKey
            )
        }
    }
}
