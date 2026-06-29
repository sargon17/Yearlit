import Foundation

public enum UnitOfMeasure: String, Codable, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case none = "None"

    /// Currency
    case currency = "Currency"

    // Quantity/Count
    case pages = "Pages"
    case items = "Items"
    case rounds = "Rounds"
    case servings = "Servings"
    case doses = "Doses"

    // Distance
    case meters = "m"
    case kilometers = "km"
    case miles = "Miles"
    case steps = "Steps"
    case floors = "Floors"

    // Volume
    case milliliters = "ml"
    case liters = "l"
    case ounces = "oz"
    case cups = "Cups"

    // Time
    case minutes = "Minutes"
    case hours = "Hours"

    // Weight
    case grams = "g"
    case kilograms = "kg"
    case pounds = "Pounds"

    // Energy/Calories
    case calories = "kcal"
    case kilojoules = "kJ"

    public enum Category: String, CaseIterable {
        case quantity = "Quantity/Count"
        case distance = "Distance"
        case volume = "Volume"
        case time = "Time"
        case weight = "Weight"
        case energy = "Energy/Calories"
        case currency = "Currency"
    }

    public var category: Category {
        switch self {
        case .pages, .items, .rounds, .servings, .doses, .none:
            return .quantity
        case .meters, .kilometers, .miles, .steps, .floors:
            return .distance
        case .milliliters, .liters, .ounces, .cups:
            return .volume
        case .minutes, .hours:
            return .time
        case .grams, .kilograms, .pounds:
            return .weight
        case .calories, .kilojoules:
            return .energy
        case .currency:
            return .currency
        }
    }

    /// Display name might be different from raw value for units like 'km'
    public var displayName: String {
        switch self {
        case .none: return String(localized: "Times")
        case .pages: return String(localized: "Pages")
        case .items: return String(localized: "Items")
        case .rounds: return String(localized: "Rounds")
        case .servings: return String(localized: "Servings")
        case .doses: return String(localized: "Doses")
        case .kilometers: return String(localized: "Kilometers (km)")
        case .meters: return String(localized: "Meters (m)")
        case .miles: return String(localized: "Miles")
        case .steps: return String(localized: "Steps")
        case .floors: return String(localized: "Floors")
        case .milliliters: return String(localized: "Milliliters (ml)")
        case .liters: return String(localized: "Liters (l)")
        case .ounces: return String(localized: "Ounces (oz)")
        case .cups: return String(localized: "Cups")
        case .minutes: return String(localized: "Minutes")
        case .hours: return String(localized: "Hours")
        case .grams: return String(localized: "Grams (g)")
        case .kilograms: return String(localized: "Kilograms (kg)")
        case .pounds: return String(localized: "Pounds")
        case .calories: return String(localized: "Calories (kcal)")
        case .kilojoules: return String(localized: "Kilojoules (kJ)")
        case .currency: return String(localized: "Currency")
        }
    }

    public static var allCasesGrouped: [Category: [UnitOfMeasure]] {
        Dictionary(grouping: allCases, by: { $0.category })
    }
}

public extension UnitOfMeasure.Category {
    var displayName: String {
        switch self {
        case .quantity: return String(localized: "Quantity/Count")
        case .distance: return String(localized: "Distance")
        case .volume: return String(localized: "Volume")
        case .time: return String(localized: "Time")
        case .weight: return String(localized: "Weight")
        case .energy: return String(localized: "Energy/Calories")
        case .currency: return String(localized: "Currency")
        }
    }
}
