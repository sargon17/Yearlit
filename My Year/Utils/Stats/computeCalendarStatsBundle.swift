import SharedModels
import SwiftUI

func computeCalendarStatsBundle(
    calendar: CustomCalendar,
    year: Int,
    todayLocal: Date,
    todaysReferenceDate: Date?
) -> StatsBundle {
    let cal = LocalDayCalendar.calendar
    let basic = computeBasicCalendarStats(for: calendar, today: todayLocal)

    func entryOn(_ date: Date) -> CalendarEntry? {
        entry(for: calendar, date: date)
    }

    func isSuccessOn(_ date: Date) -> Bool {
        isEntrySuccess(entryOn(date), calendar: calendar)
    }

    func zOn(_ date: Date) -> Double {
        normalizedProgress(for: calendar, entry: entryOn(date))
    }

    let rollingStats: (cr30: Double, avg7: Double, avg30: Double)
    let monthly: [Int: Double]
    let bestWeekday: Int?
    let weekdayRates: [Int: Double]
    let volatility: Double

    switch calendar.cadence {
    case .daily:
        rollingStats = computeRollingStatsSingle(
            cal: cal,
            todayLocal: todayLocal,
            zOn: zOn,
            isSuccessOn: isSuccessOn
        )
        let weekday = computeWeekdayRatesSingle(
            cal: cal,
            year: year,
            todayLocal: todayLocal,
            trackingType: calendar.trackingType,
            zOn: zOn,
            isSuccessOn: isSuccessOn,
            normalizeToMax: true
        )
        bestWeekday = weekday.best?.day
        weekdayRates = weekday.weekdayRates
        monthly = computeMonthlyBinaryRates(
            cal: cal,
            year: year,
            todayLocal: todayLocal,
            isSuccessOn: isSuccessOn
        )
        volatility = computeWeeklyVolatilityFromSuccess(
            cal: cal,
            todayLocal: todayLocal,
            isSuccessOn: isSuccessOn
        )
    case .weekly:
        rollingStats = computeRollingStatsWeekly(
            cal: cal,
            todayLocal: todayLocal,
            zOn: zOn,
            isSuccessOn: isSuccessOn
        )
        bestWeekday = nil
        weekdayRates = [:]
        monthly = computeMonthlyRatesWeekly(
            cal: cal,
            year: year,
            todayLocal: todayLocal,
            trackingType: calendar.trackingType,
            zOn: zOn,
            isSuccessOn: isSuccessOn
        )
        volatility = computeWeeklyVolatilityFromProgress(
            cal: cal,
            todayLocal: todayLocal,
            zOn: zOn
        )
    }

    let todaysCount = todaysReferenceDate.map { entryOn($0)?.count ?? 0 }

    return StatsBundle(
        basic: basic,
        completionRate30d: rollingStats.cr30,
        bestWeekday: bestWeekday,
        weekdayRates: weekdayRates,
        monthlyRates: monthly,
        rolling7d: rollingStats.avg7,
        rolling30d: rollingStats.avg30,
        volatilityStd: volatility,
        todaysCount: todaysCount
    )
}

private func computeBasicCalendarStats(for calendar: CustomCalendar, today: Date) -> CalendarStats {
    let activeDays = calendar.entries.values.filter { entry in
        switch calendar.trackingType {
        case .binary:
            return entry.completed
        case .counter, .multipleDaily:
            return entry.count > 0
        }
    }.count

    let totalCount = calendar.entries.values.reduce(0) { $0 + $1.count }
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 0
    let localCalendar = LocalDayCalendar.calendar
    let longestStreak = WidgetStreak.longestStreak(calendar: calendar, calendarSystem: localCalendar)
    let currentStreak = WidgetStreak.currentStreak(
        calendar: calendar,
        today: today,
        calendarSystem: localCalendar
    ).streak

    return CalendarStats(
        activeDays: activeDays,
        totalCount: totalCount,
        maxCount: maxCount,
        longestStreak: longestStreak,
        currentStreak: currentStreak
    )
}

private func recentWeekStarts(cal: Calendar, todayLocal: Date, count: Int) -> [Date] {
    let currentWeek = LocalDayCalendar.startOfWeek(for: todayLocal)
    return (0 ..< count).compactMap { offset in
        cal.date(byAdding: .weekOfYear, value: -(count - 1 - offset), to: currentWeek)
    }
}

private func computeRollingStatsWeekly(
    cal: Calendar,
    todayLocal: Date,
    zOn: (Date) -> Double,
    isSuccessOn: (Date) -> Bool
) -> (cr30: Double, avg7: Double, avg30: Double) {
    let weeks = recentWeekStarts(cal: cal, todayLocal: todayLocal, count: 12)
    guard !weeks.isEmpty else { return (0, 0, 0) }

    var successCount = 0
    var sum4 = 0.0
    var sum12 = 0.0

    for (index, weekStart) in weeks.enumerated() {
        if isSuccessOn(weekStart) {
            successCount += 1
        }

        let value = zOn(weekStart)
        sum12 += value
        if index >= weeks.count - 4 {
            sum4 += value
        }
    }

    return (
        cr30: Double(successCount) / Double(weeks.count),
        avg7: sum4 / Double(min(4, weeks.count)),
        avg30: sum12 / Double(weeks.count)
    )
}

private func computeMonthlyRatesWeekly(
    cal: Calendar,
    year: Int,
    todayLocal: Date,
    trackingType: TrackingType,
    zOn: (Date) -> Double,
    isSuccessOn: (Date) -> Bool
) -> [Int: Double] {
    let endDate = min(
        todayLocal,
        cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? todayLocal
    )
    let weeks = recentWeekStarts(cal: cal, todayLocal: endDate, count: 60).filter {
        cal.component(.year, from: $0) == year
    }

    var totals: [Int: (sum: Double, count: Int)] = [:]
    for weekStart in weeks {
        let month = cal.component(.month, from: weekStart)
        let value: Double = {
            switch trackingType {
            case .binary:
                return isSuccessOn(weekStart) ? 1 : 0
            case .counter, .multipleDaily:
                return zOn(weekStart)
            }
        }()
        let current = totals[month] ?? (0, 0)
        totals[month] = (current.sum + value, current.count + 1)
    }

    var result: [Int: Double] = [:]
    for month in 1 ... 12 {
        let current = totals[month] ?? (0, 0)
        result[month] = current.count > 0 ? current.sum / Double(current.count) : 0
    }
    return result
}

private func computeWeeklyVolatilityFromProgress(
    cal: Calendar,
    todayLocal: Date,
    zOn: (Date) -> Double
) -> Double {
    let weeks = recentWeekStarts(cal: cal, todayLocal: todayLocal, count: 12)
    guard !weeks.isEmpty else { return 0 }

    let values = weeks.map(zOn)
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}
