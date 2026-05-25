import Foundation

public enum LocalizedCountText {
    public static func backfilling(_ count: Int, cadence: CalendarCadence, locale: Locale = .current) -> String {
        String(localized: "Backfilling \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale)).")
    }

    public static func currentStreak(_ count: Int, cadence: CalendarCadence, locale: Locale = .current) -> String {
        String(localized: "Current streak: \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))")
    }

    public static func overwriteSummary(
        overwriteCount: Int,
        totalRange: Int,
        cadence: CalendarCadence,
        locale: Locale = .current
    ) -> String {
        let unit = cadenceUnit(for: cadence)
        let overwriteText = countedUnit(overwriteCount, unit: unit, locale: locale)
        let rangeText = countedUnit(totalRange, unit: unit, locale: locale)

        return String(localized: "This will overwrite \(overwriteText) in a \(rangeText) range.")
    }

    public static func daysLeft(_ count: Int, locale: Locale = .current) -> String {
        String(localized: "\(countedUnit(count, unit: .day, locale: locale)) left")
    }

    private enum Unit {
        case day
        case week
    }

    private static func cadenceUnit(for cadence: CalendarCadence) -> Unit {
        cadence == .weekly ? .week : .day
    }

    private static func countedUnit(_ count: Int, unit: Unit, locale: Locale) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.zeroFormattingBehavior = .dropAll

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar

        let components: DateComponents
        switch unit {
        case .day:
            formatter.allowedUnits = [.day]
            components = DateComponents(day: count)
        case .week:
            formatter.allowedUnits = [.weekOfMonth]
            components = DateComponents(weekOfMonth: count)
        }

        return formatter.string(from: components) ?? "\(count)"
    }
}
