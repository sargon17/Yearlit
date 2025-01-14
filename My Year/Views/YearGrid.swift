//
//  File.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import Foundation
import SwiftUI
import SharedModels
import os

private let logger = Logger(subsystem: "com.sargon17.My-Year", category: "Views")


enum DayMoodType: Hashable {
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
}

struct YearGrid: View {
    let store = ValuationStore.shared


    @State private var showingValuationPopup = false
    @State private var selectedDate: Date = Date()

    @State private var dayTypesQuantity: [DayMoodType: Int] = [:]
    
    
    // Get color for a specific day
    private func colorForDay(_ day: Int) -> Color {
        let dayDate = store.dateForDay(day)
        
        if day >= store.currentDayNumber {
            return Color("dot-inactive")
        }
        
        if let valuation = store.getValuation(for: dayDate) {
            return Color(valuation.mood.color)
        }
        
        return Color("dot-active")
    }
    
    // Calculate grid layout for vertical rectangle
    private func calculateGridDimensions(availableWidth: CGFloat, availableHeight: CGFloat, dotSize: CGFloat) -> (columns: Int, rows: Int, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        // Calculate grid dimensions based on aspect ratio, exactly as in widget
        let aspectRatio = availableWidth / availableHeight
        let targetColumns = Int(sqrt(Double(365) * aspectRatio))
        let columns = min(targetColumns, 365)
        let rows = Int(ceil(Double(365) / Double(columns)))
        
        // Calculate spacings to fill the widget, exactly as in widget
        let horizontalSpacing = (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
        let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)
        
        return (columns, rows, horizontalSpacing, verticalSpacing)
    }
    
    private func handleDayTap(_ day: Int) {
        let date = store.dateForDay(day)
        if day < store.currentDayNumber && store.getValuation(for: date) == nil {
            selectedDate = date
            showingValuationPopup = true
        }
    }


    private func updateDayTypesQuantity() {
        let evaluatedDays = store.valuations.values.reduce(into: [:]) { counts, valuation in
            counts[DayMoodType.from(valuation.mood), default: 0] += 1
        }
        
        let notEvaluatedDays = store.currentDayNumber - store.valuations.count
        let futureDays = store.numberOfDaysInYear - store.currentDayNumber
        
        var quantities = evaluatedDays
        quantities[DayMoodType.notEvaluated] = notEvaluatedDays
        quantities[DayMoodType.future] = futureDays
        
        dayTypesQuantity = quantities
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 6) {
                Text(Calendar.current.component(.year, from: Date()).description)
                    .font(.system(size: 68))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)
                
                Spacer()
                
                let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
                Text(String(format: "%.1f%%", percent * 100))
                    .font(.system(size: 38))
                    .foregroundColor(Color("text-primary").opacity(0.5))
                    .fontWeight(.regular)
            }
            .padding(.horizontal)
            
            HStack {
                MosaicChart(dayTypesQuantity: dayTypesQuantity)
                
                Spacer()
                
                Text("Left: ")
                    .font(.system(size: 22))
                    .foregroundColor(Color("text-primary").opacity(0.5))
                    .fontWeight(.regular)
                + Text("\(store.numberOfDaysInYear - store.currentDayNumber)")
                    .font(.system(size: 38))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            }
            
            GeometryReader { geometry in
                let dotSize: CGFloat = 10
                let padding: CGFloat = 20
                
                // Calculate available space
                let availableWidth = geometry.size.width - (padding * 2)
                let availableHeight = geometry.size.height - (padding * 2) // Account for header
                
                let dimensions = calculateGridDimensions(
                    availableWidth: availableWidth,
                    availableHeight: availableHeight,
                    dotSize: dotSize
                )
                
                VStack(spacing: dimensions.verticalSpacing) {
                    ForEach(0..<dimensions.rows, id: \.self) { row in
                        HStack(spacing: dimensions.horizontalSpacing) {
                            ForEach(0..<dimensions.columns, id: \.self) { col in
                                let day = row * dimensions.columns + col
                                if day < store.numberOfDaysInYear {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorForDay(day))
                                        .frame(width: dotSize, height: dotSize)
                                        .onTapGesture {
                                            handleDayTap(day)
                                        }
                                } else {
                                    Color.clear.frame(width: dotSize, height: dotSize)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
            }
        }
        .onAppear {
            checkTodayValuation()
            updateDayTypesQuantity()
            logger.info("Day types quantity: \(dayTypesQuantity)")
        }
        .onChange(of: store.valuations) { _ in
            updateDayTypesQuantity()
        }
        .sheet(isPresented: $showingValuationPopup) {
            DayValuationPopup(date: selectedDate)
        }
    }
    
    private func checkTodayValuation() {
        let today = Date()
        if store.getValuation(for: today) == nil {
            selectedDate = today
            showingValuationPopup = true
        }
    }
}

struct MosaicChart: View {
    let dayTypesQuantity: [DayMoodType: Int]
    
    var sortedEntries: [(type: DayMoodType, count: Int)] {
        dayTypesQuantity.sorted { $0.key.color < $1.key.color }
            .map { (type: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in

            let availableWidth = geometry.size.width

                HStack(spacing: 2) {            
                    ForEach(sortedEntries, id: \.type) { entry in
                        RoundedRectangle(cornerRadius: 3)
                        .fill(Color(entry.type.color))
                        .frame(width: availableWidth * CGFloat(entry.count) / CGFloat(sortedEntries.reduce(0, { $0 + $1.count })), height: 40)
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.trailing)
    }
}



#Preview {
    YearGrid()
}
