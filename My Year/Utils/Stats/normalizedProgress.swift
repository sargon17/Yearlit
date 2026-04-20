import SharedModels
import SwiftUI

func counterPercentile75ByCalendar(calendars: [CustomCalendar]) -> [UUID: Double] {
    Dictionary(uniqueKeysWithValues: calendars.map { calendar in
        guard calendar.trackingType == .counter else {
            return (calendar.id, 1.0)
        }

        let counts = calendar.entries.values.map(\.count)
        return (calendar.id, max(1.0, percentile(counts, p: 0.75)))
    })
}

func normalizedProgress(for calendar: CustomCalendar, entry: CalendarEntry?, q75: Double? = nil) -> Double {
    guard let e = entry else { return 0 }
    switch calendar.trackingType {
    case .binary:
        return e.completed ? 1 : 0
    case .counter:
        let qVal: Double
        if let q75 = q75 {
            qVal = max(1.0, q75)
        } else {
            let counts = calendar.entries.values.map { $0.count }
            qVal = max(1.0, percentile(counts, p: 0.75))
        }
        return min(Double(e.count) / qVal, 1.0)
    case .multipleDaily:
        let target = max(1, calendar.dailyTarget)
        return min(Double(e.count) / Double(target), 1.0)
    }
}
