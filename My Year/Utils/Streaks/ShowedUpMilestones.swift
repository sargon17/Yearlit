import Foundation

enum ShowedUpMilestones {
    static let baseMilestones: [Int] = [5, 10, 20, 30, 40, 50, 75, 100, 150]

    static func milestone(for showedUpCount: Int) -> Int? {
        guard showedUpCount > 0 else { return nil }
        if baseMilestones.contains(showedUpCount) {
            return showedUpCount
        }
        if showedUpCount > 150, showedUpCount % 50 == 0 {
            return showedUpCount
        }
        return nil
    }

    static func latestMilestone(for showedUpCount: Int) -> Int? {
        guard showedUpCount > 0 else { return nil }
        if showedUpCount > 150 {
            return showedUpCount - (showedUpCount % 50)
        }
        return baseMilestones.filter { $0 <= showedUpCount }.max()
    }
}
