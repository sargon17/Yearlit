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
}
