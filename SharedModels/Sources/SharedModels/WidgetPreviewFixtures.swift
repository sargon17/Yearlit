import SwiftUI

public enum WidgetPreviewFixtures {
    public static func habitCalendar(referenceDate: Date = Date()) -> CustomCalendar {
        CustomCalendar(
            name: String(localized: "Daily Training"),
            color: "qs-orange",
            cadence: .daily,
            trackingType: .binary,
            trackingStartedAt: previewTrackingStart(referenceDate: referenceDate),
            dailyTarget: 1,
            entries: binaryEntries(referenceDate: referenceDate),
            isArchived: false,
            recurringReminderEnabled: true,
            unit: UnitOfMeasure.none,
            defaultRecordValue: 1
        )
    }

    public static func counterCalendar(referenceDate: Date = Date()) -> CustomCalendar {
        CustomCalendar(
            name: String(localized: "Reading"),
            color: "mood-excellent",
            cadence: .daily,
            trackingType: .counter,
            trackingStartedAt: previewTrackingStart(referenceDate: referenceDate),
            dailyTarget: 1,
            entries: counterEntries(referenceDate: referenceDate),
            isArchived: false,
            recurringReminderEnabled: true,
            unit: .pages,
            defaultRecordValue: 10
        )
    }

    private static func binaryEntries(referenceDate: Date) -> [String: CalendarEntry] {
        let offsets = [
            -28, -27, -25, -24, -23, -21, -20, -19, -18, -16, -15, -14,
            -13, -12, -10, -9, -8, -7, -5, -4, -3, -2, -1, 0,
        ]
        return Dictionary(uniqueKeysWithValues: offsets.compactMap { offset in
            guard let date = LocalDayCalendar.calendar.date(byAdding: .day, value: offset, to: referenceDate) else {
                return nil
            }
            return (DayKeyFormatter.shared.string(from: date), CalendarEntry(date: date, count: 1, completed: true))
        })
    }

    private static func previewTrackingStart(referenceDate: Date) -> Date {
        LocalDayCalendar.calendar.date(byAdding: .day, value: -42, to: referenceDate) ?? referenceDate
    }

    private static func counterEntries(referenceDate: Date) -> [String: CalendarEntry] {
        let countsByOffset = [
            -13: 12, -12: 20, -11: 8, -10: 28, -9: 16, -8: 32, -7: 24,
            -6: 0, -5: 18, -4: 40, -3: 26, -2: 34, -1: 22, 0: 30,
        ]
        return Dictionary(uniqueKeysWithValues: countsByOffset.compactMap { offset, count in
            guard let date = LocalDayCalendar.calendar.date(byAdding: .day, value: offset, to: referenceDate) else {
                return nil
            }
            return (DayKeyFormatter.shared.string(from: date), CalendarEntry(date: date, count: count, completed: count > 0))
        })
    }
}
