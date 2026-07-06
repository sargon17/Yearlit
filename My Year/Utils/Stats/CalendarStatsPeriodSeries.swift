import SharedModels
import SwiftUI

struct CalendarStatsPeriodPoint {
  let date: Date
  let entry: CalendarEntry?
  let isSuccess: Bool
  let progress: Double
  let isClosed: Bool
}

struct CalendarStatsPeriodSeries {
  let cadence: CalendarCadence
  let points: [CalendarStatsPeriodPoint]

  var closedPoints: [CalendarStatsPeriodPoint] {
    points.filter(\.isClosed)
  }
}

func buildCalendarStatsPeriodSeries(
  cal: Calendar,
  calendar: CustomCalendar,
  entriesByBucket: [Date: CalendarEntry],
  q75: Double?,
  startDate: Date,
  todayLocal: Date
) -> CalendarStatsPeriodSeries {
  let component: Calendar.Component = calendar.cadence == .weekly ? .weekOfYear : .day
  let currentPeriodStart = statsPeriodStart(cal: cal, cadence: calendar.cadence, date: todayLocal)
  var cursor = statsPeriodStart(cal: cal, cadence: calendar.cadence, date: startDate)
  var points: [CalendarStatsPeriodPoint] = []

  while cursor <= currentPeriodStart {
    let entry = entriesByBucket[cursor]
    points.append(
      CalendarStatsPeriodPoint(
        date: cursor,
        entry: entry,
        isSuccess: isEntrySuccess(entry, calendar: calendar),
        progress: normalizedProgress(for: calendar, entry: entry, q75: q75),
        isClosed: cursor < currentPeriodStart
      )
    )

    guard let next = cal.date(byAdding: component, value: 1, to: cursor) else {
      break
    }
    cursor = statsPeriodStart(cal: cal, cadence: calendar.cadence, date: next)
  }

  return CalendarStatsPeriodSeries(cadence: calendar.cadence, points: points)
}

func statsPeriodStart(cal: Calendar, cadence: CalendarCadence, date: Date) -> Date {
  switch cadence {
  case .daily:
    return cal.startOfDay(for: date)
  case .weekly:
    return LocalDayCalendar.startOfWeek(for: date)
  }
}

func computeRollingStats(from series: CalendarStatsPeriodSeries) -> (cr30: Double, avg7: Double, avg30: Double) {
  let longCount = series.cadence == .weekly ? 12 : 30
  let shortCount = series.cadence == .weekly ? 4 : 7
  let points = Array(series.points.suffix(longCount))
  guard !points.isEmpty else { return (0, 0, 0) }

  let successCount = points.filter(\.isSuccess).count
  let shortPoints = Array(points.suffix(shortCount))
  let longProgressSum = points.reduce(0) { $0 + $1.progress }
  let shortProgressSum = shortPoints.reduce(0) { $0 + $1.progress }

  return (
    cr30: Double(successCount) / Double(points.count),
    avg7: shortProgressSum / Double(shortPoints.count),
    avg30: longProgressSum / Double(points.count)
  )
}

func computeWeekdayRates(
  cal: Calendar,
  year: Int,
  todayLocal: Date,
  series: CalendarStatsPeriodSeries,
  normalizeToMax: Bool
) -> (weekdayRates: [Int: Double], best: (day: Int, rate: Double)?) {
  var totals: [Int: (sum: Double, count: Int)] = [:]
  for point in series.points {
    guard cal.component(.year, from: point.date) == year, point.date <= todayLocal else {
      continue
    }

    let weekday = cal.component(.weekday, from: point.date)
    let current = totals[weekday] ?? (0, 0)
    totals[weekday] = (current.sum + point.progress, current.count + 1)
  }

  var rates: [Int: Double] = [:]
  var best: (day: Int, rate: Double)?
  for (weekday, total) in totals {
    let rate = total.count > 0 ? total.sum / Double(total.count) : 0
    rates[weekday] = rate
    if best == nil || rate > best!.rate {
      best = (weekday, rate)
    }
  }

  if normalizeToMax, let maxRate = rates.values.max(), maxRate > 0 {
    rates = rates.mapValues { $0 / maxRate }
  }
  return (rates, best)
}

func computeMonthlyRates(
  cal: Calendar,
  year: Int,
  todayLocal: Date,
  trackingType: TrackingType,
  series: CalendarStatsPeriodSeries
) -> [Int: Double] {
  var monthly: [Int: Double] = [:]
  for month in 1...12 {
    guard let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1)),
      let dayRange = cal.range(of: .day, in: .month, for: monthStart)
    else {
      continue
    }

    let isCurrentMonth =
      year == cal.component(.year, from: todayLocal) && month == cal.component(.month, from: todayLocal)
    let lastDay = isCurrentMonth ? cal.component(.day, from: todayLocal) : dayRange.count
    guard lastDay > 0 else {
      monthly[month] = 0
      continue
    }

    let monthPoints = series.points.filter { point in
      cal.component(.year, from: point.date) == year && cal.component(.month, from: point.date) == month
    }

    switch series.cadence {
    case .daily:
      let successes = monthPoints.filter(\.isSuccess).count
      monthly[month] = Double(successes) / Double(lastDay)
    case .weekly:
      guard !monthPoints.isEmpty else {
        monthly[month] = 0
        continue
      }
      let sum = monthPoints.reduce(0) { partial, point in
        switch trackingType {
        case .binary:
          return partial + (point.isSuccess ? 1 : 0)
        case .counter, .multipleDaily:
          return partial + point.progress
        }
      }
      monthly[month] = sum / Double(monthPoints.count)
    }
  }
  return monthly
}

func computeVolatility(cal: Calendar, todayLocal: Date, series: CalendarStatsPeriodSeries) -> Double {
  let values: [Double]

  switch series.cadence {
  case .daily:
    var weekly: [Double] = []
    var endOfWeek = cal.startOfDay(for: todayLocal)

    for _ in 0..<12 {
      guard let startOfWeek = cal.date(byAdding: .day, value: -6, to: endOfWeek) else {
        break
      }

      let points = series.points.filter { point in
        point.date >= startOfWeek && point.date <= endOfWeek
      }
      let denominator = max(1, points.count)
      let successCount = points.filter(\.isSuccess).count
      weekly.append(Double(successCount) / Double(denominator))

      guard let previous = cal.date(byAdding: .day, value: -7, to: endOfWeek) else {
        break
      }
      endOfWeek = cal.startOfDay(for: previous)
    }
    values = weekly

  case .weekly:
    values = Array(series.points.suffix(12)).map(\.progress)
  }

  guard !values.isEmpty else { return 0 }

  let mean = values.reduce(0, +) / Double(values.count)
  let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
  return sqrt(variance)
}

func computeCurrentMissedPeriods(from series: CalendarStatsPeriodSeries) -> Int {
  var missed = 0
  for point in series.closedPoints.reversed() {
    if point.isSuccess {
      break
    }
    missed += 1
  }
  return missed
}

func computeAverageRecoveryPeriods(from series: CalendarStatsPeriodSeries) -> Double? {
  var missedRun = 0
  var recoveries: [Int] = []

  for point in series.closedPoints {
    if point.isSuccess {
      if missedRun > 0 {
        recoveries.append(missedRun)
        missedRun = 0
      }
    } else {
      missedRun += 1
    }
  }

  guard !recoveries.isEmpty else { return nil }
  return Double(recoveries.reduce(0, +)) / Double(recoveries.count)
}
