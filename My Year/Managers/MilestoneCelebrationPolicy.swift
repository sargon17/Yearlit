import Foundation

struct MilestoneCelebrationDecision {
    let milestone: Int
    let shouldPresent: Bool
}

final class MilestoneCelebrationPolicy {
    static let shared = MilestoneCelebrationPolicy()

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

    func decisionForStreakMilestone(calendarId: UUID, streak: Int) -> MilestoneCelebrationDecision? {
        guard let milestone = streakTracker.milestoneToCelebrate(calendarId: calendarId, streak: streak) else {
            return nil
        }

        let shouldPresent = settings.shouldPresentStreakCelebration
        streakTracker.markRemembered(calendarId: calendarId, milestone: milestone)
        return MilestoneCelebrationDecision(milestone: milestone, shouldPresent: shouldPresent)
    }

    func decisionForShowedUpMilestone(
        calendarId: UUID,
        showedUpCount: Int,
        kind: ShowedUpMilestoneKind,
        periodKey: String
    ) -> MilestoneCelebrationDecision? {
        guard
            let milestone = showedUpTracker.milestoneToCelebrate(
                calendarId: calendarId,
                showedUpCount: showedUpCount,
                kind: kind,
                periodKey: periodKey
            )
        else { return nil }

        let shouldPresent = settings.shouldPresentShowedUpCelebration(for: kind)
        showedUpTracker.markRemembered(
            calendarId: calendarId,
            milestone: milestone,
            kind: kind,
            periodKey: periodKey
        )
        return MilestoneCelebrationDecision(milestone: milestone, shouldPresent: shouldPresent)
    }
}
