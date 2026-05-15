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
                .font(AppFont.mono(18))
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
                .font(AppFont.mono(16))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(data.calendar.cadence == .weekly ? "Weekly Streak Focus" : "Streak Focus")
                .font(AppFont.mono(12))
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
                .font(AppFont.mono(10))
                .foregroundColor(.textSecondary)
            Text("\(value)")
                .font(AppFont.mono(36))
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
                        title: data.completionWindowTitle,
                        value: sharePercent(data.completionRateTrailingLongWindow),
                        accentColor: data.accentColor
                    )
                    ShareCompactStatTile(
                        title: data.shortTrendTitle,
                        value: sharePercent(data.averageProgressTrailingShortWindow),
                        accentColor: data.accentColor
                    )
                    ShareCompactStatTile(
                        title: data.averageWindowTitle,
                        value: sharePercent(data.averageProgressTrailingLongWindow),
                        accentColor: data.accentColor
                    )
                }

                if data.calendar.cadence == .daily, let bestWeekday = data.bestWeekday {
                    HStack {
                        Text("Best Weekday")
                            .font(AppFont.mono(10))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(shareWeekdayName(bestWeekday))
                            .font(AppFont.mono(18))
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
                .font(AppFont.mono(16))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Performance")
                .font(AppFont.mono(12))
                .foregroundColor(Color("text-tertiary"))
        }
    }
}
