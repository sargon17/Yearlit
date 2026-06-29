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

struct CalendarStatsPeriodSeriesInput {
  let cal: Calendar
  let calendar: CustomCalendar
  let entriesByBucket: [Date: CalendarEntry]
  let q75: Double?
  let startDate: Date
  let todayLocal: Date
}

struct RollingStats {
  let completionRateTrailingLongWindow: Double
  let averageProgressTrailingShortWindow: Double
  let averageProgressTrailingLongWindow: Double
}

func buildCalendarStatsPeriodSeries(_ input: CalendarStatsPeriodSeriesInput) -> CalendarStatsPeriodSeries {
  let component: Calendar.Component = input.calendar.cadence == .weekly ? .weekOfYear : .day
  let currentPeriodStart = statsPeriodStart(
    cal: input.cal,
    cadence: input.calendar.cadence,
    date: input.todayLocal
  )
  var cursor = statsPeriodStart(cal: input.cal, cadence: input.calendar.cadence, date: input.startDate)
  var points: [CalendarStatsPeriodPoint] = []

  while cursor <= currentPeriodStart {
    let entry = input.entriesByBucket[cursor]
    points.append(
      CalendarStatsPeriodPoint(
        date: cursor,
        entry: entry,
        isSuccess: isEntrySuccess(entry, calendar: input.calendar),
        progress: normalizedProgress(for: input.calendar, entry: entry, q75: input.q75),
        isClosed: cursor < currentPeriodStart
      )
    )

    guard let next = input.cal.date(byAdding: component, value: 1, to: cursor) else {
      break
    }
    cursor = statsPeriodStart(cal: input.cal, cadence: input.calendar.cadence, date: next)
  }

  return CalendarStatsPeriodSeries(cadence: input.calendar.cadence, points: points)
}

func statsPeriodStart(cal: Calendar, cadence: CalendarCadence, date: Date) -> Date {
  switch cadence {
  case .daily:
    return cal.startOfDay(for: date)
  case .weekly:
    return LocalDayCalendar.startOfWeek(for: date)
  }
}

func computeRollingStats(from series: CalendarStatsPeriodSeries) -> RollingStats {
  let longCount = series.cadence == .weekly ? 12 : 30
  let shortCount = series.cadence == .weekly ? 4 : 7
  let points = Array(series.points.suffix(longCount))
  guard !points.isEmpty else {
    return RollingStats(
      completionRateTrailingLongWindow: 0,
      averageProgressTrailingShortWindow: 0,
      averageProgressTrailingLongWindow: 0
    )
  }

  let successCount = points.filter(\.isSuccess).count
  let shortPoints = Array(points.suffix(shortCount))
  let longProgressSum = points.reduce(0) { $0 + $1.progress }
  let shortProgressSum = shortPoints.reduce(0) { $0 + $1.progress }

  return RollingStats(
    completionRateTrailingLongWindow: Double(successCount) / Double(points.count),
    averageProgressTrailingShortWindow: shortProgressSum / Double(shortPoints.count),
    averageProgressTrailingLongWindow: longProgressSum / Double(points.count)
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
    let rate = total.count >= 1 ? total.sum / Double(total.count) : 0
    rates[weekday] = rate
    if best.map({ rate > $0.rate }) ?? true {
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
  trackingType: TrackingType,
  series: CalendarStatsPeriodSeries
) -> [Int: Double] {
  var monthly: [Int: Double] = [:]
  for month in 1...12 {
    let monthPoints = series.points.filter { point in
      cal.component(.year, from: point.date) == year && cal.component(.month, from: point.date) == month
    }

    switch series.cadence {
    case .daily:
      guard !monthPoints.isEmpty else {
        monthly[month] = 0
        continue
      }
      let successes = monthPoints.filter(\.isSuccess).count
      monthly[month] = Double(successes) / Double(monthPoints.count)
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
