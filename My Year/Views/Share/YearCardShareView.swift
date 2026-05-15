import SharedModels
import SwiftDate
import SwiftUI

struct YearCardShareView: View {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let stats: CalendarStats
    let completionRateTrailingLongWindow: Double
    let currentPeriodCount: Int
    let trackingType: TrackingType

    private var shareData: ShareCardData {
        ShareCardData(
            calendar: calendar,
            year: year,
            dates: dates,
            stats: stats,
            completionRateTrailingLongWindow: completionRateTrailingLongWindow,
            averageProgressTrailingShortWindow: 0,
            averageProgressTrailingLongWindow: 0,
            bestWeekday: nil,
            currentPeriodCount: currentPeriodCount,
            trackingType: trackingType
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            CustomSeparator()
                .padding(.horizontal, -28)

            ShareCalendarGridView(calendar: calendar, dates: dates)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statsSection

            CustomSeparator()
                .padding(.horizontal, -28)
            footer
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("surface-muted"))
                .overlay(NoiseLayer(opacity: 1, blendMode: nil))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color("devider-top"), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(calendar.name.capitalized)
                .font(AppFont.mono(18))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            CustomSeparator()
                .padding(.horizontal, -28)
            HStack {
                Text("Statistics")
                    .font(AppFont.mono(16))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)
                Spacer()
            }
            HStack(spacing: 12) {
                ShareCompactStatTile(
                    title: shareData.currentPeriodTitle,
                    value: "\(currentPeriodCount)",
                    accentColor: Color(calendar.color)
                )
                ShareCompactStatTile(
                    title: "Total",
                    value: "\(stats.totalCount)",
                    accentColor: Color(calendar.color)
                )
                if trackingType != .binary {
                    ShareCompactStatTile(
                        title: shareData.bestPeriodTitle,
                        value: "\(stats.maxCount)",
                        accentColor: Color(calendar.color)
                    )
                }
            }
            HStack(spacing: 12) {
                ShareCompactStatTile(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    accentColor: Color(calendar.color)
                )
                ShareCompactStatTile(
                    title: "Longest Streak",
                    value: "\(stats.longestStreak)",
                    accentColor: Color(calendar.color)
                )
                ShareCompactStatTile(
                    title: shareData.completionWindowTitle,
                    value: sharePercent(completionRateTrailingLongWindow),
                    accentColor: Color(calendar.color)
                )
            }
        }
    }

    private var footer: some View {
        ShareCardFooter()
    }
}
