import SwiftUI

struct CalendarStats {
  public let activeDays: Int
  public let totalCount: Int
  public let maxCount: Int
  public let longestStreak: Int
  public let currentStreak: Int
}

struct CalendarStatisticsView: View {
  let stats: CalendarStats

  var body: some View {
    VStack {
      Text("Calendar Statistics")
    }
  }
}

