import Garnish
import SharedModels
import SwiftUI

func colorForDay(
    _ day: Date,
    calendar: CustomCalendar,
    today: Date,
    counts: [Int]
) -> Color {
    colorForDay(day, calendar: calendar, today: today, precomputedScale: precomputeRobustDotScale(for: counts))
}

/// Variant for tight loops: pass a precomputed scale to avoid recomputing it per cell.
func colorForDay(
    _ day: Date,
    calendar: CustomCalendar,
    today: Date,
    precomputedScale: Double
) -> Color {
    let comparisonDate = calendar.bucketDate(for: today)
    let bucketDate = calendar.bucketDate(for: day)

    guard bucketDate <= comparisonDate else {
        return futureDayColor()
    }

    let emptyColor = bucketDate == comparisonDate ? activeDayColor() : missedDayColor()

    if let entry: CalendarEntry = calendar.entry(for: day) {
        switch calendar.trackingType {
        case .binary:
            return entry.completed ? Color(calendar.color) : emptyColor
        case .counter:
            if entry.count > 0 {
                let ratio = counterDotFillRatio(count: entry.count, precomputedScale: precomputedScale)
                return GarnishColor.blend(.surfaceMuted, with: Color(calendar.color), ratio: ratio)
            } else {
                return emptyColor
            }
        case .multipleDaily:
            if entry.count > 0 {
                let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
                return Color(calendar.color).opacity(opacity)
            } else {
                return emptyColor
            }
        }
    }

    return emptyColor
}
