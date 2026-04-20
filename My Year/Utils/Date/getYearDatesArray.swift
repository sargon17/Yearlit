import Foundation
import SharedModels
import SwiftDate

private enum YearDatesCache {
    struct Key: Hashable {
        let year: Int
        let timeZoneIdentifier: String
    }

    static let lock = NSLock()
    static var values: [Key: [Date]] = [:]
}

public func getYearDatesArray() -> [Date] {
    let currentYear = Calendar.current.component(.year, from: Date())
    return getYearDatesArray(for: currentYear)
}

public func getYearDatesArray(for year: Int) -> [Date] {
    let timeZone = TimeZone.autoupdatingCurrent
    let cacheKey = YearDatesCache.Key(year: year, timeZoneIdentifier: timeZone.identifier)

    YearDatesCache.lock.lock()
    if let cachedDates = YearDatesCache.values[cacheKey] {
        defer { YearDatesCache.lock.unlock() }
        return cachedDates
    }
    YearDatesCache.lock.unlock()

    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = timeZone
    guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
          let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
    else {
        return []
    }

    var dates: [Date] = []
    var current = startDate
    while current <= endDate {
        dates.append(current)
        guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
        current = next
    }

    YearDatesCache.lock.lock()
    YearDatesCache.values[cacheKey] = dates
    YearDatesCache.lock.unlock()

    return dates
}

public func getYearWeekDatesArray(for year: Int) -> [Date] {
    let calendar = LocalDayCalendar.calendar
    guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
          let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
    else {
        return []
    }

    var weeks: [Date] = []
    var cursor = LocalDayCalendar.startOfWeek(for: startDate)
    let lastWeek = LocalDayCalendar.startOfWeek(for: endDate)

    while cursor <= lastWeek {
        weeks.append(cursor)
        guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
        cursor = next
    }

    return weeks
}
