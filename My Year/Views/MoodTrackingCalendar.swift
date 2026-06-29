//
//  MoodTrackingCalendar.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import Foundation
import SharedModels
import SwiftDate
import SwiftUI
import SwiftfulRouting
import os

private let logger = Logger(subsystem: "com.sargon17.My-Year", category: "Views")

struct MoodTrackingCalendar: View {
  let store = ValuationStore.shared
  @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
  @AppStorage("lastMoodPromptDayKey") private var lastMoodPromptDayKey: String = ""
  @Environment(\.router) private var router

  @State private var valuationPopupDate: Date?
  @State private var isShowingValuationSheet = false
  @State private var dayTypesQuantity: [DayMoodType: Int] = [:]
  @State private var showRemainingDays: Bool = true
  @State private var isLabelVisible: Bool = true

  private var currentDayIndex: Int {
    max(0, store.currentDayNumber - 1)
  }

  private func colorForDay(_ day: Int) -> Color {
    let dayDate = dateForDay(day, in: store.selectedYear)

    if day > currentDayIndex {
      return futureDayColor()
    }

    if let valuation = store.getValuation(for: dayDate) {
      return Color(valuation.mood.color)
    }

    return day == currentDayIndex ? activeDayColor() : missedDayColor()
  }

  private func handleDayTap(_ day: Int) {
    guard isMoodTrackingEnabled else { return }
    let date = dateForDay(day, in: store.selectedYear)
    if day <= currentDayIndex {
      valuationPopupDate = date
    }
  }

  private func checkTodayValuation() {
    guard isMoodTrackingEnabled else { return }
    let today = Date()
    let localToday = DateInRegion(today, region: .current)
    guard localToday.hour >= 18 else { return }
    let todayKey = localToday.toFormat("yyyy-MM-dd")
    guard lastMoodPromptDayKey != todayKey else { return }
    if store.getValuation(for: today) == nil {
      lastMoodPromptDayKey = todayKey
      valuationPopupDate = today
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 10) {
        HStack(alignment: .center, spacing: 6) {
          Text(Calendar.current.component(.year, from: Date()).description)
            .font(AppFont.sans(68))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.black)

          Spacer()

          let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
          Text(String(format: "%.1f%%", percent * 100))
            .font(AppFont.sans(38))
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
            Text(String(localized: showRemainingDays ? "Left: " : "Passed: "))
              .font(AppFont.mono(12))
              .foregroundColor(Color("text-tertiary"))
              .fontWeight(.regular)
              .opacity(isLabelVisible ? 1 : 0)

            Text(
              showRemainingDays
                ? "\(store.numberOfDaysInYear - store.currentDayNumber)"
                : "\(store.currentDayNumber)"
            )
            .font(AppFont.sans(38))
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
      .padding(.vertical, 12)

      CustomSeparator()

      GeometryReader { geometry in
        let layout = CalendarGridLayout(size: geometry.size, dayCount: store.numberOfDaysInYear)

        Canvas { context, _ in
          for day in 0..<store.numberOfDaysInYear {
            let center = layout.center(for: day)
            let rect = CGRect(
              x: center.x - (CalendarGridLayout.dotSize / 2),
              y: center.y - (CalendarGridLayout.dotSize / 2),
              width: CalendarGridLayout.dotSize,
              height: CalendarGridLayout.dotSize
            )
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(colorForDay(day)))
          }
        }
        .contentShape(Rectangle())
        .gesture(
          SpatialTapGesture()
            .onEnded { value in
              guard let day = layout.index(nearest: value.location), day < store.numberOfDaysInYear else {
                return
              }
              handleDayTap(day)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      .onChange(of: valuationPopupDate) { _, newDate in
        guard let newDate, isMoodTrackingEnabled, !isShowingValuationSheet else { return }
        isShowingValuationSheet = true
        router.showScreen(.sheet) { _ in
          DayValuationPopup(date: newDate)
            .onDisappear {
              isShowingValuationSheet = false
              valuationPopupDate = nil
            }
        }
      }
  }

}

enum VisualizationType {
  case full
  case pastOnly
  case evaluatedOnly
}
