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
  let valuationStore: ValuationStore
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var store: CustomCalendarStore
  @State private var showDeleteConfirmation = false
  @State private var showEditSheet = false
  @Binding var isReorderActive: Bool

  let latestSlotsCount = 28
  let columnsCount = 7

  var latestSlots: [Date] {
    let today = DateInRegion()
    let fromDate = today - (latestSlotsCount - 1).days

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
  }
}

extension CalendarsOverviewsItem {
  var ui: some View {
    VStack(alignment: .leading, spacing: 12) {

      Text(calendar.name.capitalized)
        .font(.system(size: 14, design: .monospaced))
        .fontWeight(.bold)
        .foregroundColor(.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

      latestSlotsView
        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
        .aspectRatio(7 / 4, contentMode: .fit)

      Text(calendar.trackingType.description)
        .font(.system(size: 10))
        .foregroundColor(.textTertiary)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
    .cardStyle()
  }

  var latestSlotsView: some View {
    GeometryReader { geometry in
      let totalWidth = geometry.size.width
      let spacing = 6.0
      let totalSpacing = spacing * (max(CGFloat(columnsCount) - 1.0, 0.0))
      let itemWidth = (totalWidth - totalSpacing) / CGFloat(columnsCount)
      LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columnsCount),
        spacing: spacing
      ) {
        ForEach(latestSlots, id: \.self) { slot in
          VisualEntry(
            width: itemWidth,
            color: colorForDay(
              slot,
              calendar: calendar,
              valuationStore: valuationStore,
            )
          )
        }
      }
    }
  }
}

struct VisualEntry: View {
  let width: CGFloat
  let color: Color

  var body: some View {
    Rectangle()
      .fill(color)
      .frame(width: width, height: width)
      .cornerRadius(4)
  }
}
