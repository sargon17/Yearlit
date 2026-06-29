import AppIntents
import Foundation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

public enum VisualizationType: String, Codable, AppEnum {
    case full
    case pastOnly
    case evaluatedOnly

    @available(macOS 13.0, *)
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Visualization Type"
    }

    @available(macOS 13.0, *)
    public static var caseDisplayRepresentations: [VisualizationType: DisplayRepresentation] {
        [
            .full: "Full Year",
            .pastOnly: "Past Days Only",
            .evaluatedOnly: "Evaluated Days Only",
        ]
    }
}

@available(macOS 10.15, *)
public struct MosaicChart: View {
    public let dayTypesQuantity: [DayMoodType: Int]

    @State var visualizationType: VisualizationType = .pastOnly

    public init(dayTypesQuantity: [DayMoodType: Int], visualizationType: VisualizationType? = nil) {
        self.dayTypesQuantity = dayTypesQuantity
        self.visualizationType = visualizationType ?? .pastOnly
    }

    public var sortedEntries: [(type: DayMoodType, count: Int)] {
        dayTypesQuantity.sorted { lhs, rhs in
            switch (lhs.key, rhs.key) {
            case let (.mood(m1), .mood(m2)):
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
                if case .mood = entry.type {
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
                            .frame(
                                width: calculateWidth(for: entry, availableWidth: availableWidth), height: .infinity
                            )
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        )
                    )
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

            #if canImport(UIKit)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            #endif
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

    public func calculateWidth(for entry: (type: DayMoodType, count: Int), availableWidth: CGFloat)
        -> CGFloat
    {
        let totalCount = filteredEntries.reduce(0) { $0 + $1.count }
        guard totalCount > 0 else { return 0 }
        return availableWidth * CGFloat(entry.count) / CGFloat(totalCount)
    }
}

@available(iOS 17.0, macOS 14.0, *)
public func updateDayTypesQuantity(store: ValuationStore) -> [DayMoodType: Int] {
    let calendar = LocalDayCalendar.calendar
    let selectedYear = store.selectedYear
    let evaluatedDays = store.valuations.values
        .filter { calendar.component(.year, from: $0.timestamp) == selectedYear }
        .reduce(into: [:]) { counts, valuation in
            counts[DayMoodType.from(valuation.mood), default: 0] += 1
        }

    let evaluatedDaysCount = evaluatedDays.values.reduce(0) { $0 + $1 }
    let notEvaluatedDays = max(0, store.currentDayNumber - evaluatedDaysCount)
    let futureDays = store.numberOfDaysInYear - store.currentDayNumber

    var quantities = evaluatedDays
    quantities[DayMoodType.notEvaluated] = notEvaluatedDays
    quantities[DayMoodType.future] = futureDays

    return quantities
}
