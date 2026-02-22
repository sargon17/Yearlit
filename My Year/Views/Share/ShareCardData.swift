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
}
