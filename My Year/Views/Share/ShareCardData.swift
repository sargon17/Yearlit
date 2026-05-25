import SharedModels
import SwiftUI

struct ShareCardData {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let your365Snapshot: Your365Snapshot?
    let isYour365FirstYear: Bool
    let stats: CalendarStats
    let completionRateTrailingLongWindow: Double
    let averageProgressTrailingShortWindow: Double
    let averageProgressTrailingLongWindow: Double
    let bestWeekday: Int?
    let currentPeriodCount: Int
    let trackingType: TrackingType

    var accentColor: Color {
        Color(calendar.color)
    }

    var currentPeriodTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "This Week" : "Today"
    }

    var bestPeriodTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "Best Week" : "Best Day"
    }

    var shortTrendTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "4w" : "7d"
    }

    var longTrendTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "12w" : "30d"
    }

    var completionWindowTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "12w CR" : "30d CR"
    }

    var averageWindowTitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "12w Avg" : "30d Avg"
    }

    var performanceSubtitle: LocalizedStringKey {
        calendar.cadence == .weekly ? "Trends and weekly progress" : "Trends and best day"
    }

    var streakUnitPlural: String {
        calendar.cadence == .weekly ? String(localized: "weeks") : String(localized: "days")
    }

    var your365Title: LocalizedStringKey {
        isYour365FirstYear ? "Your 365" : "Latest 365 Days"
    }

    var your365Subtitle: String {
        guard let snapshot = your365Snapshot else { return "" }
        if isYour365FirstYear {
            if let todayCell = snapshot.todayCell {
                return String(localized: "Day \(todayCell.dayNumber) of your 365")
            }
        }
        return String(localized: "Started \(formattedStartDate(snapshot.trackingStartedAt))")
    }

    private func formattedStartDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
