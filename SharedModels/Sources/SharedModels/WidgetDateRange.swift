import Foundation

public enum WidgetDateRange {
    public static func recentDays(endingAt date: Date, count: Int) -> [Date] {
        let end = LocalDayCalendar.startOfDay(for: date)
        guard let start = LocalDayCalendar.calendar.date(byAdding: .day, value: -(count - 1), to: end) else {
            return [end]
        }
        return days(from: start, to: end)
    }

    public static func daysInYear(containing date: Date) -> [Date] {
        let calendar = LocalDayCalendar.calendar
        let year = calendar.component(.year, from: date)
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
        else {
            return []
        }
        return days(from: start, to: end)
    }

    public static func recentWeeks(endingAt date: Date, count: Int) -> [Date] {
        let end = LocalDayCalendar.startOfWeek(for: date)
        guard let start = LocalDayCalendar.calendar.date(
            byAdding: .weekOfYear,
            value: -(count - 1),
            to: end
        ) else {
            return [end]
        }
        return weeks(from: start, to: end)
    }

    public static func weeksInYear(containing date: Date) -> [Date] {
        let calendar = LocalDayCalendar.calendar
        let year = calendar.component(.year, from: date)
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))
        else {
            return []
        }
        return weeks(from: start, to: end)
    }

    public static func days(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = LocalDayCalendar.calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }
        return dates
    }

    public static func weeks(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = LocalDayCalendar.startOfWeek(for: start)
        let last = LocalDayCalendar.startOfWeek(for: end)

        while current <= last {
            dates.append(current)
            guard let next = LocalDayCalendar.calendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: current
            ) else {
                break
            }
            current = next
        }

        return dates
    }
}
