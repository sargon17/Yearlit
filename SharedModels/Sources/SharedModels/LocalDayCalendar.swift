import Foundation

public enum LocalDayCalendar {
    public static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    public static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func startOfWeek(for date: Date) -> Date {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval.start
        }
        return startOfDay(for: date)
    }
}
