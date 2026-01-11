import SharedModels
import SwiftUI

struct StreakMilestoneCardView: View {
  let calendar: CustomCalendar
  let milestone: Int
  let currentStreak: Int
  let dates: [Date]

  var body: some View {
    ShareCardContainer {
      VStack(alignment: .leading, spacing: 10) {
        header

        CustomSeparator()
          .padding(.horizontal, -28)

        streakBlock

        ShareCalendarGridView(calendar: calendar, dates: dates)
          .frame(maxWidth: .infinity, maxHeight: .infinity)

        CustomSeparator()
          .padding(.horizontal, -28)
        ShareCardFooter()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(calendar.name.capitalized)
        .font(.system(size: 16, design: .monospaced))
        .foregroundColor(Color("text-primary"))
        .fontWeight(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text("Streak Milestone")
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color("text-tertiary"))
    }
  }

  private var streakBlock: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Milestone hit")
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(.textSecondary)
      Text("\(milestone)")
        .font(.system(size: 48, design: .monospaced))
        .foregroundColor(Color(calendar.color))
        .fontWeight(.black)
      Text("Day streak")
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(.textSecondary)
      if currentStreak != milestone {
        Text("Current streak: \(currentStreak) days")
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(.textSecondary)
      }
    }
  }
}
