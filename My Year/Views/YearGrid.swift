//
//  File.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import Foundation
import SwiftUI

struct YearGrid: View {
    let year = Calendar.current.component(.year, from: Date())
    
    // Calculate number of days in the year
    var numberOfDaysInYear: Int {
        let calendar = Calendar.current
        
        // Create date components for the first and last day of the year
        let startOfYear = DateComponents(year: year, month: 1, day: 1)
        let endOfYear = DateComponents(year: year, month: 12, day: 31)
        
        // Convert to actual dates
        guard let startDate = calendar.date(from: startOfYear),
              let endDate = calendar.date(from: endOfYear) else {
            return 365 // Default to 365 if calculation fails
        }
        
        // Calculate the difference in days
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 365
        return days + 1 // Add 1 because dateComponents gives difference (e.g., Dec 31 - Jan 1 = 364)
    }
    
    // Calculate current day number in year
    var currentDayNumber: Int {
        let calendar = Calendar.current
        let today = Date()
        return calendar.ordinality(of: .day, in: .year, for: today) ?? 0
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
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 6) {
                    Text(year.description).font(.system(size: 68)).foregroundColor(Color("text-primary")).fontWeight(.black)
                
                Spacer()

                let percent = Double(currentDayNumber) / 365.0
                Text(String(format: "%.1f%%", percent * 100)).font(.system(size: 38)).foregroundColor(Color("text-primary").opacity(0.5)).fontWeight(.regular)
                

            }.padding(.horizontal)

            HStack {

                Spacer()

                Text("Left: ").font(.system(size: 22)).foregroundColor(Color("text-primary").opacity(0.5)).fontWeight(.regular)
                + Text("\(365 - currentDayNumber)").font(.system(size: 38)).foregroundColor(Color("text-primary")).fontWeight(.bold)
            }.padding(.horizontal)

            GeometryReader { geometry in
                let dotSize: CGFloat = 5
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
                                if day < 365 {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(day < currentDayNumber ? Color("dot-active") : Color("dot-inactive"))
                                        .frame(width: dotSize, height: dotSize)
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
    }
}

#Preview {
    YearGrid()
}
