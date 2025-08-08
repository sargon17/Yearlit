//
//  File.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import Foundation
import SharedModels
import SwiftUI
import os

private let logger = Logger(subsystem: "com.sargon17.My-Year", category: "Views")

struct MoodTrackingCalendar: View {
  let store = ValuationStore.shared
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true

  @State private var valuationPopup: (isPresented: Bool, date: Date)?
  @State private var dayTypesQuantity: [DayMoodType: Int] = [:]
  @State private var showRemainingDays: Bool = true
  @State private var isLabelVisible: Bool = true

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
    let startOfYear = calendar.date(
      from: DateComponents(year: store.selectedYear, month: 1, day: 1))!

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
      VStack(spacing: 10) {
        HStack(alignment: .center, spacing: 6) {
          Text(Calendar.current.component(.year, from: Date()).description)
            .font(.system(size: 68, design: .monospaced))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.black)

          Spacer()

          let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
          Text(String(format: "%.1f%%", percent * 100))
            .font(.system(size: 38, design: .monospaced))
            .foregroundColor(Color("text-tertiary"))
            .fontWeight(.regular)
        }
        .padding(.top, 10)
        .padding(.horizontal)

        HStack {

          SharedModels.MosaicChart(dayTypesQuantity: dayTypesQuantity)
            .frame(height: 40).frame(width: 200)

          Spacer()

          HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(showRemainingDays ? "Left: " : "Passed: ")
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("text-tertiary"))
              .fontWeight(.regular)
              .opacity(isLabelVisible ? 1 : 0)

            Text(
              showRemainingDays
                ? "\(store.numberOfDaysInYear - store.currentDayNumber)"
                : "\(store.currentDayNumber)"
            )
            .font(.system(size: 38, design: .monospaced))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.bold)
            .contentTransition(.numericText())
          }
          .onTapGesture {
            Task {
              let labelAnimationDuration = 0.2
              let numberTransitionDuration = 0.3

              withAnimation(.easeInOut(duration: labelAnimationDuration)) {
                isLabelVisible = false
              }
              try? await Task.sleep(for: .seconds(labelAnimationDuration))

              withAnimation(.easeInOut) {
                showRemainingDays.toggle()
              }

              try? await Task.sleep(for: .seconds(numberTransitionDuration))

              withAnimation(.easeInOut(duration: labelAnimationDuration)) {
                isLabelVisible = true
              }
            }
          }
        }
        .padding(.horizontal)

      }

      CustomSeparator()

      GeometryReader { geometry in
        let dotSize: CGFloat = 10
        let padding: CGFloat = 20

        let availableWidth = geometry.size.width - (padding * 2)
        let availableHeight = geometry.size.height - (padding * 2)

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
      .frame(height: UIScreen.main.bounds.height - 270)
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
      .sheet(
        isPresented: Binding(
          get: { valuationPopup?.isPresented ?? false },
          set: { if !$0 { valuationPopup = nil } }
        )
      ) {
        if let date = valuationPopup?.date, isMoodTrackingEnabled {
          DayValuationPopup(date: date)
        }
      }
  }

  private func calculateGridDimensions(
    availableWidth: CGFloat, availableHeight: CGFloat, dotSize: CGFloat
  ) -> (columns: Int, rows: Int, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
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
