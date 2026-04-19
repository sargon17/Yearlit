import SharedModels
import SwiftDate
import SwiftUI

struct YearCardShareView: View {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let stats: CalendarStats
    let completionRate30d: Double
    let todaysCount: Int
    let trackingType: TrackingType

    private var shareData: ShareCardData {
        ShareCardData(
            calendar: calendar,
            year: year,
            dates: dates,
            stats: stats,
            completionRate30d: completionRate30d,
            rolling7d: 0,
            rolling30d: 0,
            bestWeekday: nil,
            todaysCount: todaysCount,
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
                .font(.system(size: 18, design: .monospaced))
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
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)
                Spacer()
            }
            HStack(spacing: 12) {
                ShareCompactStatTile(
                    title: shareData.currentPeriodTitle,
                    value: "\(todaysCount)",
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
                    value: sharePercent(completionRate30d),
                    accentColor: Color(calendar.color)
                )
            }
        }
    }

    private var footer: some View {
        ShareCardFooter()
    }
}
