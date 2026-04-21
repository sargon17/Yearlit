import Foundation

public enum LocalizedCountText {
    public static func backfilling(_ count: Int, cadence: CalendarCadence, locale: Locale = .current) -> String {
        switch languageCode(for: locale) {
        case "it":
            return "Compilazione retroattiva di \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))."
        case "uk":
            return "Заповнення \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))."
        default:
            return "Backfilling \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))."
        }
    }

    public static func currentStreak(_ count: Int, cadence: CalendarCadence, locale: Locale = .current) -> String {
        switch languageCode(for: locale) {
        case "it":
            return "Serie attuale: \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))"
        case "uk":
            return "Поточна серія: \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))"
        default:
            return "Current streak: \(countedUnit(count, unit: cadenceUnit(for: cadence), locale: locale))"
        }
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

        switch languageCode(for: locale) {
        case "it":
            return "Sovrascriverà \(overwriteText) in un intervallo di \(rangeText)."
        case "uk":
            return "Буде перезаписано \(overwriteText) в діапазоні \(rangeText)."
        default:
            return "This will overwrite \(overwriteText) in a \(rangeText) range."
        }
    }

    public static func daysLeft(_ count: Int, locale: Locale = .current) -> String {
        switch languageCode(for: locale) {
        case "it":
            if count == 1 {
                return "Manca 1 giorno"
            }
            return "Mancano \(count) giorni"
        case "uk":
            return "Залишилося \(countedUnit(count, unit: .day, locale: locale))"
        default:
            return "\(countedUnit(count, unit: .day, locale: locale)) left"
        }
    }

    private enum Unit {
        case day
        case week
    }

    private static func cadenceUnit(for cadence: CalendarCadence) -> Unit {
        cadence == .weekly ? .week : .day
    }

    private static func countedUnit(_ count: Int, unit: Unit, locale: Locale) -> String {
        let languageCode = languageCode(for: locale)

        switch languageCode {
        case "it":
            let singular = unit == .day ? "giorno" : "settimana"
            let plural = unit == .day ? "giorni" : "settimane"
            let noun = count == 1 ? singular : plural
            return "\(count) \(noun)"
        case "uk":
            let forms: (one: String, few: String, many: String) = unit == .day
                ? ("день", "дні", "днів")
                : ("тиждень", "тижні", "тижнів")
            return "\(count) \(ukrainianForm(for: count, forms: forms))"
        default:
            let singular = unit == .day ? "day" : "week"
            let plural = unit == .day ? "days" : "weeks"
            let noun = count == 1 ? singular : plural
            return "\(count) \(noun)"
        }
    }

    private static func ukrainianForm(for count: Int, forms: (one: String, few: String, many: String)) -> String {
        let absoluteCount = abs(count)
        let mod10 = absoluteCount % 10
        let mod100 = absoluteCount % 100

        if mod10 == 1, mod100 != 11 {
            return forms.one
        }

        if (2...4).contains(mod10), !(12...14).contains(mod100) {
            return forms.few
        }

        return forms.many
    }

    private static func languageCode(for locale: Locale) -> String {
        locale.language.languageCode?.identifier ?? locale.identifier
    }
}
