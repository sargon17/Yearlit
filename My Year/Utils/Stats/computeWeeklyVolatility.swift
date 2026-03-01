import SwiftUI

func computeWeeklyVolatility(
    cal: Calendar,
    todayLocal: Date,
    anySuccessByDay: [Date: Bool]
) -> Double {
    var weekly: [Double] = []
    // Normalize to start-of-day so keys match [Date: Bool] entries.
    var endOfWeek = cal.startOfDay(for: todayLocal)

    for _ in 0 ..< 12 {
        guard let startOfWeekRaw = cal.date(byAdding: .day, value: -6, to: endOfWeek) else { break }
        let startOfWeek = cal.startOfDay(for: startOfWeekRaw)
        var succ = 0
        var denom = 0
        var d = startOfWeek
        while d <= endOfWeek {
            let key = cal.startOfDay(for: d)
            succ += (anySuccessByDay[key] == true) ? 1 : 0
            denom += 1
            guard let nd = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = nd
        }
        weekly.append(denom > 0 ? Double(succ) / Double(denom) : 0)
        guard let prevRaw = cal.date(byAdding: .day, value: -7, to: endOfWeek) else { break }
        endOfWeek = cal.startOfDay(for: prevRaw)
    }

    guard !weekly.isEmpty else { return 0 }
    let mean = weekly.reduce(0, +) / Double(weekly.count)
    let variance = weekly.reduce(0) { $0 + pow($1 - mean, 2) } / Double(weekly.count)
    return sqrt(variance)
}
