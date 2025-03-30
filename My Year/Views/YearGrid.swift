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


struct YearGrid: View {
    let store = ValuationStore.shared
    @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true

    @State private var valuationPopup: (isPresented: Bool, date: Date)?
    @State private var dayTypesQuantity: [DayMoodType: Int] = [:]
    
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
    
    private func handleDayTap(_ day: Int) {
        guard isMoodTrackingEnabled else { return }
        let date = store.dateForDay(day)
        if day < store.currentDayNumber && store.getValuation(for: date) == nil {
            valuationPopup = (true, date)
        }
    }
    
    private func checkTodayValuation() {
        guard isMoodTrackingEnabled else { return }
        let today = Date()
        if store.getValuation(for: today) == nil {
            valuationPopup = (true, today)
        }
    }

    private func fillRandomValuations() {
        let calendar = Calendar.current
        let today = Date()
        let startOfYear = calendar.date(from: DateComponents(year: store.selectedYear, month: 1, day: 1))!
        
        for day in 0..<store.currentDayNumber {
            let date = calendar.date(byAdding: .day, value: day, to: startOfYear)!
            if date <= today && store.getValuation(for: date) == nil {
                let randomMood = [DayMood.terrible, .bad, .neutral, .good, .excellent].randomElement()!
                store.setValuation(randomMood, for: date)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(store.year.description)")
                    .font(.system(size: 32, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(Color("text-primary"))
                
                if My_YearApp.isDebugMode {
                    Button(action: fillRandomValuations) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(Color("text-tertiary"))
                    }
                    .padding(.leading, 4)
                }

                Spacer()
                
                Text("Left: ")
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                + Text("\(store.numberOfDaysInYear - store.currentDayNumber)")
                    .font(.system(size: 20))
                    .foregroundColor(Color("text-primary"))
                    .fontWeight(.black)
            }
            .foregroundColor(Color("text-primary").opacity(0.5))
            .fontWeight(.regular)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
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

                SharedModels.MosaicChart(dayTypesQuantity: dayTypesQuantity)
                    .frame(height: 40)
                
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
        }.overlay {
            HStack {
                Rectangle()
                .fill(Color("devider-bottom"))
                .frame(maxHeight: .infinity, alignment: .trailing)
                .frame(maxWidth: 1)

                Spacer()
                
                Rectangle()
                    .fill(Color("devider-top"))
                    .frame(maxHeight: .infinity, alignment: .trailing)
                    .frame(maxWidth: 1)
                
                }
      }.ignoresSafeArea(edges: .bottom)
        .onAppear {
            checkTodayValuation()
            dayTypesQuantity = updateDayTypesQuantity(store: store)
        }
        .onChange(of: store.valuations) { _, _ in
            dayTypesQuantity = updateDayTypesQuantity(store: store)
        }
        .sheet(isPresented: Binding(
            get: { valuationPopup?.isPresented ?? false },
            set: { if !$0 { valuationPopup = nil } }
        )) {
            if let date = valuationPopup?.date, isMoodTrackingEnabled {
                DayValuationPopup(date: date)
            }
        }
    }
    
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
}

enum VisualizationType {
    case full
    case pastOnly
    case evaluatedOnly
}





#Preview {
    YearGrid()
}
