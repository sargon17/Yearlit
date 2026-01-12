import Foundation
import SharedModels

struct ExistingStreakBuildResult {
  let entries: [String: CalendarEntry]
  let overwriteCount: Int
  let totalDays: Int
}

func buildExistingStreakEntries(
  startDate: Date,
  endDate: Date,
  trackingType: TrackingType,
  dailyTarget: Int,
  dailyValue: Int,
  existingEntries: [String: CalendarEntry]
) -> ExistingStreakBuildResult {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  let startDay = calendar.startOfDay(for: startDate)
  let endDay = calendar.startOfDay(for: endDate)

  var entries: [String: CalendarEntry] = [:]
  var overwriteCount = 0
  var totalDays = 0

  var cursor = startDay
  while cursor <= endDay {
    let key = dayKey(for: cursor)
    if existingEntries[key] != nil {
      overwriteCount += 1
    }
    let count: Int
    let completed: Bool
    switch trackingType {
    case .binary:
      count = 1
      completed = true
    case .counter:
      count = dailyValue
      completed = dailyValue > 0
    case .multipleDaily:
      count = dailyTarget
      completed = dailyTarget > 0
    }
    entries[key] = CalendarEntry(date: cursor, count: count, completed: completed)
    totalDays += 1
    guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
    cursor = next
  }

  return ExistingStreakBuildResult(
    entries: entries,
    overwriteCount: overwriteCount,
    totalDays: totalDays
  )
}
