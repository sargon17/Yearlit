import SharedModels
import SwiftUI

func computeStreaks(cal: Calendar, _ anySuccessByDay: [Date: Bool]) -> (longest: Int, current: Int) {
  guard !anySuccessByDay.isEmpty else { return (0, 0) }

  // Normalize keys to start-of-day to avoid TZ/time-component drift.
  var norm: [Date: Bool] = [:]
  for (d, v) in anySuccessByDay {
    norm[cal.startOfDay(for: d)] = v
  }
  let days = norm.keys.sorted()

  // Longest requires consecutive days.
  var longest = 0
  var temp = 0
  var prev: Date?
  for day in days {
    if let p = prev,
      let expected = cal.date(byAdding: .day, value: 1, to: p),
      !cal.isDate(day, inSameDayAs: expected)
    {
      temp = 0
    }
    if norm[day] == true {
      temp += 1
      longest = max(longest, temp)
    } else {
      temp = 0
    }
    prev = day
  }

  let current = WidgetStreak.currentStreak(
    successByDay: norm,
    today: Date(),
    calendarSystem: cal,
    allowTodayMissing: true
  ).streak

  return (longest, current)
}
