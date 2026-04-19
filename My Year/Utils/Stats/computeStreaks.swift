import SharedModels
import SwiftUI

func computeStreaks(cal: Calendar, _ anySuccessByDay: [Date: Bool]) -> (longest: Int, current: Int) {
    let successDays = Set(anySuccessByDay.compactMap { day, didSucceed in
        didSucceed ? cal.startOfDay(for: day) : nil
    })
    return computeStreaks(cal: cal, successDays: successDays, today: Date())
}

func computeStreaks(cal: Calendar, successDays: Set<Date>, today: Date = Date()) -> (longest: Int, current: Int) {
    guard !successDays.isEmpty else { return (0, 0) }

    let normalizedSuccessDays = Set(successDays.map { cal.startOfDay(for: $0) })
    let sortedDays = normalizedSuccessDays.sorted()

    var longest = 0
    var streak = 0
    var previous: Date?

    for day in sortedDays {
        if let previous,
           let expected = cal.date(byAdding: .day, value: 1, to: previous),
           !cal.isDate(day, inSameDayAs: expected)
        {
            streak = 0
        }

        streak += 1
        longest = max(longest, streak)
        previous = day
    }

    let current = WidgetStreak.currentStreak(
        successByDay: Dictionary(uniqueKeysWithValues: normalizedSuccessDays.map { ($0, true) }),
        today: today,
        calendarSystem: cal,
        allowTodayMissing: true
    ).streak

    return (longest, current)
}
