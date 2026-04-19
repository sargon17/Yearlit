import SharedModels
import SwiftUI

struct ShareCardData {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let stats: CalendarStats
    let completionRate30d: Double
    let rolling7d: Double
    let rolling30d: Double
    let bestWeekday: Int?
    let todaysCount: Int
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
        calendar.cadence == .weekly ? "weeks" : "days"
    }
}
