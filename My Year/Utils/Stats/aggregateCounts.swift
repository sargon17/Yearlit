import SharedModels
import SwiftUI

func aggregateCounts(
    cal: Calendar,
    calendars: [CustomCalendar]
) -> (totalCount: Int, perDayTotal: [Date: Int]) {
    var totalCount = 0
    var perDayTotal: [Date: Int] = [:]
    let bucketedEntries = buildEntriesByCalendarByBucket(calendars: calendars)
    for entriesByBucket in bucketedEntries.values {
        for (bucketDate, entry) in entriesByBucket {
            totalCount += entry.count
            let day = cal.startOfDay(for: bucketDate)
            perDayTotal[day, default: 0] += entry.count
        }
    }
    return (totalCount, perDayTotal)
}
