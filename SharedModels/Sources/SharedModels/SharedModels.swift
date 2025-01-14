import Foundation
import SwiftUI
import Observation
import WidgetKit
import AppIntents

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

public enum DayMoodType: Hashable {
    case mood(DayMood)  // Wraps the existing DayMood cases
    case notEvaluated   // For days that could be evaluated but weren't
    case future         // For future days
    
    // Helper to convert DayMood to this type
    static func from(_ mood: DayMood) -> DayMoodType {
        return .mood(mood)
    }
    
    var color: String {
        switch self {
        case .mood(let mood):
            return mood.color
        case .notEvaluated:
            return "dot-active"
        case .future:
            return "dot-inactive"
        }
    }
    
    // Add sorting priority
    var sortOrder: Int {
        switch self {
        case .mood(let mood):
            switch mood {
            case .terrible: return 0
            case .bad: return 1
            case .neutral: return 2
            case .good: return 3
            case .excellent: return 4
            }
        case .notEvaluated: return 5
        case .future: return 6
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

    public var year: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return year
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

public enum VisualizationType: String, Codable, AppEnum {
    case full
    case pastOnly
    case evaluatedOnly
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Visualization Type"
    }
    
    public static var caseDisplayRepresentations: [VisualizationType: DisplayRepresentation] {
        [
            .full: "Full Year",
            .pastOnly: "Past Days Only",
            .evaluatedOnly: "Evaluated Days Only"
        ]
    }
}

public struct MosaicChart: View {
    public let dayTypesQuantity: [DayMoodType: Int]

    @State var visualizationType: VisualizationType = .full
    
    public init(dayTypesQuantity: [DayMoodType: Int], visualizationType: VisualizationType? = nil) {
        self.dayTypesQuantity = dayTypesQuantity
        self.visualizationType = visualizationType ?? .full
    }

    public var sortedEntries: [(type: DayMoodType, count: Int)] {
        dayTypesQuantity.sorted { lhs, rhs in
            switch (lhs.key, rhs.key) {
            case (.mood(let m1), .mood(let m2)):
                return m1.rawValue < m2.rawValue
            case (.mood, _):
                return true
            case (_, .mood):
                return false
            case (.notEvaluated, .future):
                return true
            case (.future, .notEvaluated):
                return false
            default:
                return true
            }
        }
        .map { (type: $0.key, count: $0.value) }
    }


    public var filteredEntries: [(type: DayMoodType, count: Int)] {
        sortedEntries.filter { entry in
            switch visualizationType {
            case .full: return true
            case .pastOnly: return entry.type != .future
            case .evaluatedOnly:
                if case .mood(_) = entry.type {
                    return true
                }
                return false
            }
        }
    }

    public var body: some View {
        VStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width

                HStack(spacing: 2) {            
                    ForEach(filteredEntries, id: \.type) { entry in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(entry.type.color))
                            .frame(width: calculateWidth(for: entry, availableWidth: availableWidth), height: .infinity)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
                .animation(.spring(duration: 0.3, bounce: 0.2), value: visualizationType)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: filteredEntries.map { $0.count })
            }
        }
        .frame(height: .infinity)
        .padding(.trailing)
        .onTapGesture {
            withAnimation {
                handleTap()
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    public func handleTap() {
        if visualizationType == .full {
            visualizationType = .pastOnly
        } else if visualizationType == .pastOnly {
            visualizationType = .evaluatedOnly
        } else if visualizationType == .evaluatedOnly {
            visualizationType = .full
        }
    }

    public func calculateWidth(for entry: (type: DayMoodType, count: Int), availableWidth: CGFloat) -> CGFloat {
        let totalCount = filteredEntries.reduce(0) { $0 + $1.count }
        return availableWidth * CGFloat(entry.count) / CGFloat(totalCount)
    }
}

public func updateDayTypesQuantity(store: ValuationStore) -> [DayMoodType: Int] {
    let evaluatedDays = store.valuations.values.reduce(into: [:]) { counts, valuation in
        counts[DayMoodType.from(valuation.mood), default: 0] += 1
    }
    
    let notEvaluatedDays = store.currentDayNumber - store.valuations.count
    let futureDays = store.numberOfDaysInYear - store.currentDayNumber
    
    var quantities = evaluatedDays
    quantities[DayMoodType.notEvaluated] = notEvaluatedDays
    quantities[DayMoodType.future] = futureDays
    
    return quantities
}