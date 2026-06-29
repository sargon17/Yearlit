import SharedModels
import SwiftUI

struct MinimalGridShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 8) {
                ShareCardHeader(title: data.calendar.name.capitalized)

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
}

struct StreakFocusShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                ShareCardHeader(
                    title: data.calendar.name.capitalized,
                    subtitle: String(
                        localized: data.calendar.cadence == .weekly ? "Weekly Streak Focus" : "Streak Focus"
                    ),
                    titleSize: 16
                )

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
                ShareCardHeader(
                    title: data.calendar.name.capitalized,
                    subtitle: String(localized: "Performance"),
                    titleSize: 16
                )

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
}

struct Your365ShareView: View {
    let data: ShareCardData

    var body: some View {
        ShareCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                header

                CustomSeparator()
                    .padding(.horizontal, -28)

                if let snapshot = data.your365Snapshot {
                    ShareCalendarGridView(snapshot: snapshot, calendar: data.calendar)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    statRow(snapshot: snapshot)
                } else {
                    unavailableState
                }

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

            Text(data.your365Title)
                .font(AppFont.mono(12))
                .foregroundColor(data.accentColor)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(data.your365Subtitle)
                .font(AppFont.mono(12))
                .foregroundColor(Color("text-tertiary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func statRow(snapshot: Your365Snapshot) -> some View {
        HStack(spacing: 12) {
            ShareCompactStatTile(
                title: "Completed",
                value: "\(snapshot.cells.filter { $0.state == .completed }.count)",
                accentColor: data.accentColor
            )
            ShareCompactStatTile(
                title: "Today",
                value: snapshot.todayCell.map { "\($0.dayNumber)" } ?? "—",
                accentColor: data.accentColor
            )
        }
    }

    private var unavailableState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your 365 is available for daily calendars only.")
                .font(AppFont.mono(13))
                .foregroundColor(Color("text-secondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
