import Foundation

enum StreakMilestones {
    static let baseMilestones: [Int] = [1, 2, 3, 5, 10, 15, 20, 25, 30]

    static func milestone(for streak: Int) -> Int? {
        guard streak > 0 else { return nil }
        if baseMilestones.contains(streak) {
            return streak
        }
        if streak >= 40, streak % 10 == 0 {
            return streak
        }
        return nil
    }

    static func latestMilestone(for streak: Int) -> Int? {
        guard streak > 0 else { return nil }
        if streak >= 40 {
            return streak - (streak % 10)
        }
        return baseMilestones.filter { $0 <= streak }.max()
    }
}
