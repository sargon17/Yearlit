import Foundation
import SwiftUI
import Observation
import WidgetKit

public enum DayMood: String, Codable {
    case terrible = "😫"
    case bad = "😞"
    case neutral = "😐"
    case good = "😊"
    case excellent = "🤩"
    
    public var color: String {
        switch self {
        case .terrible: return "mood-terrible"
        case .bad: return "mood-bad"
        case .neutral: return "mood-neutral"
        case .good: return "mood-good"
        case .excellent: return "mood-excellent"
        }
    }
}

public struct DayValuation: Codable, Identifiable, Equatable {
    public let id: String // Format: "YYYY-MM-DD"
    public let mood: DayMood
    public let timestamp: Date
    
    public init(date: Date = Date(), mood: DayMood) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.mood = mood
        self.timestamp = date
    }
    
    public static func == (lhs: DayValuation, rhs: DayValuation) -> Bool {
        return lhs.id == rhs.id && lhs.mood == rhs.mood
    }
}

@Observable
public class ValuationStore {
    public static let shared = ValuationStore()
    private let appGroupId = "group.sargon17.My-Year"
    private let valuationsKey = "dayValuations"
    private let defaults: UserDefaults
    private var isLoading = false
    
    public var valuations: [String: DayValuation] = [:] {
        didSet {
            if !isLoading {
                saveValuations()
            }
        }
    }
    
    // MARK: - Date Calculations
    
    public func dateForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        return calendar.date(byAdding: .day, value: day, to: startOfYear)!
    }
    
    public var currentDayNumber: Int {
        let calendar = Calendar.current
        let today = Date()
        return calendar.ordinality(of: .day, in: .year, for: today) ?? 0
    }
    
    public var numberOfDaysInYear: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let startOfYear = DateComponents(year: year, month: 1, day: 1)
        let endOfYear = DateComponents(year: year, month: 12, day: 31)
        guard let startDate = calendar.date(from: startOfYear),
              let endDate = calendar.date(from: endOfYear) else {
            return 365
        }
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 365
        return days + 1
    }
    
    // MARK: - Initialization
    
    public init() {
        UserDefaults.standard.addSuite(named: appGroupId)
        
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            fatalError("Failed to initialize UserDefaults with App Group: \(appGroupId)")
        }
        self.defaults = defaults
        
        loadValuations()
    }
    
    public func loadValuations() {
        isLoading = true
        defer { isLoading = false }
        
        CFPreferencesAppSynchronize(appGroupId as CFString)
        
        guard let data = defaults.data(forKey: valuationsKey),
              let decoded = try? JSONDecoder().decode([String: DayValuation].self, from: data) else {
            return
        }
        
        valuations = decoded
    }
    
    public func getValuation(for date: Date) -> DayValuation? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return valuations[key]
    }
    
    public func setValuation(_ mood: DayMood, for date: Date = Date()) {
        let valuation = DayValuation(date: date, mood: mood)
        valuations[valuation.id] = valuation
        
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    private func saveValuations() {
        guard let encoded = try? JSONEncoder().encode(valuations) else {
            return
        }
        
        CFPreferencesSetAppValue(valuationsKey as CFString,
                               encoded as CFData,
                               appGroupId as CFString)
        CFPreferencesAppSynchronize(appGroupId as CFString)
        
        defaults.set(encoded, forKey: valuationsKey)
        
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    public func clearAllValuations() {
        valuations.removeAll()
        defaults.removeObject(forKey: valuationsKey)
        defaults.synchronize()
        
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
} 