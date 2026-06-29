import Foundation

public enum WidgetStreak {
    public static func longestStreak(
        calendar: CustomCalendar,
        calendarSystem: Calendar = WidgetStreak.makeLocalCalendar()
    ) -> Int {
        let successByDay = successByBucket(calendar: calendar, calendarSystem: calendarSystem)
        return longestStreak(
            successByDay: successByDay,
            calendarSystem: calendarSystem,
            cadence: calendar.cadence
        )
    }

    public static func currentStreak(
        calendar: CustomCalendar,
        today: Date = Date(),
        calendarSystem: Calendar = WidgetStreak.makeLocalCalendar(),
        allowTodayMissing: Bool = true
    ) -> (streak: Int, isAtRisk: Bool) {
        let successByDay = successByBucket(calendar: calendar, calendarSystem: calendarSystem)

        return currentStreak(
            successByDay: successByDay,
            today: today,
            calendarSystem: calendarSystem,
            cadence: calendar.cadence,
            allowTodayMissing: allowTodayMissing
        )
    }

    public static func currentStreak(
        successByDay: [Date: Bool],
        today: Date = Date(),
        calendarSystem: Calendar = WidgetStreak.makeLocalCalendar(),
        cadence: CalendarCadence = .daily,
        allowTodayMissing: Bool = true
    ) -> (streak: Int, isAtRisk: Bool) {
        guard !successByDay.isEmpty else { return (0, false) }

        let component = dateComponent(for: cadence)
        let normalizedToday = normalizedBucketDate(
            for: today,
            cadence: cadence,
            calendarSystem: calendarSystem
        )
        var normalized: [Date: Bool] = [:]
        for (date, success) in successByDay {
            let key = normalizedBucketDate(for: date, cadence: cadence, calendarSystem: calendarSystem)
            normalized[key] = normalized[key, default: false] || success
        }

        let todaySuccess = normalized[normalizedToday]
        let shouldSkipToday = allowTodayMissing && (todaySuccess == nil || todaySuccess == false)

        var streak = 0
        var cursor = normalizedToday
        var isAtRisk = false

        if shouldSkipToday {
            guard let previous = calendarSystem.date(byAdding: component, value: -1, to: normalizedToday) else {
                return (0, false)
            }
            cursor = normalizedBucketDate(for: previous, cadence: cadence, calendarSystem: calendarSystem)
            isAtRisk = true
        }

        while normalized[cursor] == true {
            streak += 1
            guard let previous = calendarSystem.date(byAdding: component, value: -1, to: cursor) else {
                break
            }
            cursor = normalizedBucketDate(for: previous, cadence: cadence, calendarSystem: calendarSystem)
        }

        if streak == 0 {
            isAtRisk = false
        }

        return (streak, isAtRisk)
    }

    private static func isEntrySuccess(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
        switch calendar.trackingType {
        case .binary:
            return entry.completed
        case .counter:
            return entry.hasLoggedCount
        case .multipleDaily:
            return entry.count >= calendar.dailyTarget
        }
    }

    public static func makeLocalCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    private static func normalizedBucketDate(
        for date: Date,
        cadence: CalendarCadence,
        calendarSystem: Calendar
    ) -> Date {
        switch cadence {
        case .daily:
            return calendarSystem.startOfDay(for: date)
        case .weekly:
            return calendarSystem.dateInterval(of: .weekOfYear, for: date)?.start
                ?? calendarSystem.startOfDay(for: date)
        }
    }

    private static func dateComponent(for cadence: CalendarCadence) -> Calendar.Component {
        cadence == .weekly ? .weekOfYear : .day
    }

    private static func successByBucket(
        calendar: CustomCalendar,
        calendarSystem: Calendar
    ) -> [Date: Bool] {
        var successByDay: [Date: Bool] = [:]
        for entry in calendar.entries.values {
            let day = normalizedBucketDate(
                for: entry.date,
                cadence: calendar.cadence,
                calendarSystem: calendarSystem
            )
            if isEntrySuccess(entry, calendar: calendar) {
                successByDay[day] = true
            }
        }
        return successByDay
    }

    private static func longestStreak(
        successByDay: [Date: Bool],
        calendarSystem: Calendar,
        cadence: CalendarCadence
    ) -> Int {
        let sortedDays = successByDay.keys.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        let component = dateComponent(for: cadence)
        var longest = 0
        var current = 0
        var previous: Date?

        for day in sortedDays {
            if let previous,
               let expected = calendarSystem.date(byAdding: component, value: 1, to: previous),
               normalizedBucketDate(for: expected, cadence: cadence, calendarSystem: calendarSystem) != day
            {
                current = 0
            }

            if successByDay[day] == true {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }

            previous = day
        }

        return longest
    }
}
