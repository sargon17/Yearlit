import Foundation

enum StreakMilestones {
    static let baseMilestones: [Int] = [3, 7, 14, 30, 50, 100]
    private static let recurringMilestoneInterval: Int = 100
    private static let recurringMilestoneStart: Int = 200

    static func milestone(for streak: Int) -> Int? {
        guard streak > 0 else { return nil }
        if baseMilestones.contains(streak) {
            return streak
        }
        if streak >= recurringMilestoneStart, streak % recurringMilestoneInterval == 0 {
            return streak
        }
        return nil
    }

    static func latestMilestone(for streak: Int) -> Int? {
        guard streak > 0 else { return nil }
        if streak >= recurringMilestoneStart {
            return streak - (streak % recurringMilestoneInterval)
        }
        return baseMilestones.filter { $0 <= streak }.max()
    }

    static func nextMilestone(after streak: Int) -> Int {
        let nextBaseMilestone = baseMilestones.first { $0 > streak }
        if let nextBaseMilestone {
            return nextBaseMilestone
        }

        return max(
            recurringMilestoneStart,
            ((max(streak, 0) / recurringMilestoneInterval) + 1) * recurringMilestoneInterval
        )
    }
}
