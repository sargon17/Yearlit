import SwiftUI

struct MinimalGridShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 8) {
                header

                CustomSeparator()
                    .padding(.horizontal, -28)

                ShareCalendarGridView(calendar: data.calendar, dates: data.dates)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomSeparator()
                    .padding(.horizontal, -28)
                ShareCardFooter()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.calendar.name.capitalized)
                .font(.system(size: 18, design: .monospaced))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct StreakFocusShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                header

                CustomSeparator()
                    .padding(.horizontal, -28)

                streakRow

                ShareCalendarGridView(calendar: data.calendar, dates: data.dates)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomSeparator()
                    .padding(.horizontal, -28)
                ShareCardFooter()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.calendar.name.capitalized)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Streak Focus")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
        }
    }

    private var streakRow: some View {
        HStack(spacing: 12) {
            streakTile(title: "Current", value: data.stats.currentStreak)
            streakTile(title: "Longest", value: data.stats.longestStreak)
        }
    }

    private func streakTile(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.textSecondary)
            Text("\(value)")
                .font(.system(size: 36, design: .monospaced))
                .foregroundColor(data.accentColor)
                .fontWeight(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PerformanceShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                header

                CustomSeparator()
                    .padding(.horizontal, -28)

                HStack(spacing: 12) {
                    ShareCompactStatTile(
                        title: "30d",
                        value: sharePercent(data.completionRate30d),
                        accentColor: data.accentColor
                    )
                    ShareCompactStatTile(
                        title: "7d",
                        value: sharePercent(data.rolling7d),
                        accentColor: data.accentColor
                    )
                    ShareCompactStatTile(
                        title: "30d Avg",
                        value: sharePercent(data.rolling30d),
                        accentColor: data.accentColor
                    )
                }

                if let bestWeekday = data.bestWeekday {
                    HStack {
                        Text("Best Weekday")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(shareWeekdayName(bestWeekday))
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundColor(data.accentColor)
                            .fontWeight(.black)
                    }
                }

                ShareCalendarGridView(calendar: data.calendar, dates: data.dates)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomSeparator()
                    .padding(.horizontal, -28)
                ShareCardFooter()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.calendar.name.capitalized)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Performance")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
        }
    }
}
