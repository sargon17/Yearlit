//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI

struct CalendarOverviewSheet: View {
  let store: CustomCalendarStore
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss


  var body: some View {
    NavigationView {
      ScrollView {
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
          ], spacing: 16
        ) {
          // Year Grid Card
          Button {
            selectedIndex = 0
            dismiss()
          } label: {
            VStack(alignment: .leading, spacing: 12) {
              Text("Year Calendar")
                .font(.headline)
                .foregroundColor(Color("text-primary"))
              Text("Daily mood tracking")
                .font(.caption)
                .foregroundColor(Color("text-tertiary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color("surface-primary"))
            .cornerRadius(12)
          }

          // Custom Calendar Cards
          ForEach(store.calendars) { calendar in
            CalendarOverviewSheetItem(
              calendar: calendar, selectedIndex: $selectedIndex, store: store)
          }
        }
        .padding()
      }
      .background(Color("surface-muted"))
      .navigationTitle("Calendars")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct CalendarOverviewSheetItem: View {
  let calendar: CustomCalendar
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  let store: CustomCalendarStore
@State private var showDeleteConfirmation = false

  @State private var isContextMenuPresented = false

  var body: some View {
    Button {
      selectedIndex = store.calendars.firstIndex(where: { $0.id == calendar.id })! + 1
      dismiss()
    } label: {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(calendar.name.capitalized)
            .font(.headline)
            .foregroundColor(Color("text-primary"))
          Spacer()
          Circle()
            .fill(Color(calendar.color))
            .frame(width: 12, height: 12)
        }
        Text(calendar.trackingType.description)
          .font(.caption)
          .foregroundColor(Color("text-tertiary"))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color("surface-primary"))
      .cornerRadius(12)
    }.onLongPressGesture {
      isContextMenuPresented = true
    }
    .contextMenu {
      Button(action: {
        showDeleteConfirmation = true
      }) {
        Text("Delete Calendar")
      }
    }.alert("Delete Calendar?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        store.deleteCalendar(id: calendar.id)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to delete '\(calendar.name)'? This action cannot be undone.")
    }
  }
}

struct ContentView: View {
  @State private var customerInfo: CustomerInfo?
  private let store = CustomCalendarStore.shared
  @State private var showingCreateSheet = false
  @State private var displayPaywall = false
  @State private var selectedIndex = 0
  @State private var showingOverview = false
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

  var body: some View {
    NavigationView {
      TabView(
        selection: $selectedIndex.onChange { _ in
          impactGenerator.impactOccurred()
        }
      ) {
        // Year Grid
        YearGrid()
          .tag(0)

        // Custom Calendars
        ForEach(store.calendars) { calendar in
          CustomCalendarView(calendarId: calendar.id)
            .tag(store.calendars.firstIndex(where: { $0.id == calendar.id }) ?? 0 + 1)
        }

        // Add Calendar Button
        VStack {
          Spacer()
          VStack(spacing: 16) {
            Image(systemName: "plus")
              .font(.system(size: 42))
              .foregroundStyle(Color("text-secondary"))
            Text("Add Calendar")
              .font(.headline)
              .foregroundColor(Color("text-primary"))
          }
          Spacer()
        }
        .tag(store.calendars.count + 1)
        .onTapGesture {
          handleAddCalendar()
        }
      }
      .gesture(
        MagnificationGesture()
          .onEnded { value in
            if value < 1.0 {
              impactGenerator.impactOccurred()
              showingOverview = true
            }
          }
      )
      .tabViewStyle(.page)
      .indexViewStyle(.page(backgroundDisplayMode: .never))
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if customerInfo?.entitlements["premium"]?.isActive ?? false {
            HStack(spacing: 4) {
              Text("Yearlit").font(.headline).foregroundColor(Color("text-primary"))
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(Color("mood-excellent"))
                .shadow(color: Color("mood-excellent").opacity(0.5), radius: 10)
            }
          } else {
            Text("Yearlit").font(.headline).foregroundColor(Color("text-primary"))
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingOverview = true }) {
            Image(systemName: "square.grid.2x2")
              .foregroundColor(Color("text-primary"))
          }
        }
      }
      .background(Color("surface-muted"))
    }
    .onAppear {
      Purchases.shared.getCustomerInfo { (customerInfo, _) in
        self.customerInfo = customerInfo
      }
    }
    .sheet(isPresented: $showingCreateSheet) {
      NavigationView {
        CreateCalendarView { newCalendar in
          store.addCalendar(newCalendar)
          selectedIndex = store.calendars.count  // Switch to the newly added calendar
          showingCreateSheet = false
        }
        .background(Color("surface-muted"))
      }
      .background(Color("surface-muted"))
    }
    .sheet(isPresented: $showingOverview) {
      CalendarOverviewSheet(store: store, selectedIndex: $selectedIndex)
    }
    .sheet(isPresented: $displayPaywall) {
      PaywallView(displayCloseButton: true)
    }
  }

  func handleAddCalendar() {
    if customerInfo?.entitlements["premium"]?.isActive ?? false || store.calendars.count < 3 {
      showingCreateSheet = true
    } else {
      displayPaywall = true
    }
  }
}

extension Binding {
  func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
    Binding(
      get: { self.wrappedValue },
      set: { newValue in
        self.wrappedValue = newValue
        handler(newValue)
      }
    )
  }
}

#Preview {
  ContentView()
}
