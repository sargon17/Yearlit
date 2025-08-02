//
//  CalendarsOverviewsItem.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 01/08/25.
//

import SharedModels
import SwiftData
import SwiftDate
import SwiftUI

struct CalendarsOverviewsItem: View {
  let calendar: CustomCalendar
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var store: CustomCalendarStore
  @State private var showDeleteConfirmation = false
  @State private var showEditSheet = false
  @Binding var isReorderActive: Bool

  let latestSlotsCount = 24

  var latestsDays: [CalendarEntry] {
    Array(
      calendar.entries.values
    )
    .sorted { $0.date > $1.date }
    .prefix(latestSlotsCount)
    .map { $0 }
  }

  var latestSlots: [Date] {
    let today = DateInRegion()
    let fromDate = today - latestSlotsCount.days

    let increment = DateComponents.create { $0.day = 1 }

    let dates = DateInRegion.enumerateDates(from: fromDate, to: today, increment: increment)

    return dates.map { $0.date }
  }

  var body: some View {
    ui
      .modifier(
        ContextOrDragModifier(
          isReorderActive: isReorderActive, calendar: calendar, store: store,
          showEditSheet: $showEditSheet, showDeleteConfirmation: $showDeleteConfirmation)
      )
      .alert("Delete Calendar?", isPresented: $showDeleteConfirmation) {
        Button("Delete", role: .destructive) {
          store.deleteCalendar(id: calendar.id)
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Are you sure you want to delete '\(calendar.name)'? This action cannot be undone.")
      }
      .sheet(isPresented: $showEditSheet) {
        NavigationView {
          EditCalendarView(
            calendar: calendar,
            onSave: { _ in
              showEditSheet = false
            },
            onDelete: { _ in
              showEditSheet = false
              store.deleteCalendar(id: calendar.id)
            }
          )
        }
        .background(Color("surface-muted"))
      }
      .onAppear {
        print("latestsDays: \(latestsDays)")
      }
  }
}

extension CalendarsOverviewsItem {
  var ui: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Rectangle()
          .fill(Color(calendar.color))
          .frame(width: 12, height: 12)
          .cornerRadius(3)

        Text(calendar.name.capitalized)
          .font(.system(size: 18, design: .monospaced))
          .fontWeight(.bold)
          .foregroundColor(Color("text-primary"))
          .lineLimit(2)
          .minimumScaleFactor(0.5)
          .multilineTextAlignment(.leading)
      }

      latestSlotsView
        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .border(Color.red)

      Text(calendar.trackingType.description)
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(Color("text-tertiary"))
        .lineLimit(2)
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
    .padding()
    .background(Color.surfaceSecondary)
    .cornerRadius(12)
  }

  var latestSlotsView: some View {
    GeometryReader { geometry in
      let totalWidth = geometry.size.width
      let itemWidth = (totalWidth - 4 * 4) / 5
      LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: 4), count: 5),
        spacing: 4
      ) {
        ForEach(latestSlots, id: \.self) { slot in
          let isActive = latestsDays.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: slot) })
          VisualEntry(
            width: itemWidth,
            isActive: isActive
          )
        }
      }
    }
  }
}

struct VisualEntry: View {
  let width: CGFloat
  let isActive: Bool

  var body: some View {
    Rectangle()
      .fill(isActive ? Color.red : Color.blue)
      .frame(width: width, height: width)
      .cornerRadius(3)
  }
}
