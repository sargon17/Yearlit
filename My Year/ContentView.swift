//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftData
import SwiftUI
import UIKit

struct CalendarOverviewSheet: View {
  @ObservedObject var store: CustomCalendarStore
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @State private var isReorderActive = false

  var body: some View {
    NavigationView {
      ScrollView {
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
          ], spacing: 8
        ) {
          // Year Grid Card
          VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
              Circle()
                .fill(Color("mood-excellent"))
                .frame(width: 12, height: 12)

              Text("Year")
                .font(.system(size: 18))
                .fontWeight(.bold)
                .foregroundColor(Color("text-primary"))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
            }

            Spacer()

            Text("Track your year mood")
              .font(.system(size: 11))
              .foregroundColor(Color("text-tertiary"))
              .lineLimit(2)
              .minimumScaleFactor(0.5)
              .multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .padding()
          .background(Color("surface-primary"))
          .cornerRadius(12)
          .aspectRatio(1.4, contentMode: .fit)
          .onTapGesture {
            selectedIndex = 0
            dismiss()
          }.opacity(isReorderActive ? 0.5 : 1)

          // Custom Calendar Cards
          ForEach(
            Array(store.calendars.sorted { $0.order < $1.order }.enumerated()), id: \.element.id
          ) { index, calendar in
            CalendarOverviewSheetItem(
              calendar: calendar, selectedIndex: $selectedIndex, store: store,
              isReorderActive: $isReorderActive
            )
            .onTapGesture {
              selectedIndex = index + 2
              dismiss()
            }
          }
        }
        .padding()
        .animation(.spring(), value: store.calendars.map { $0.order })
      }
      .background(Color("surface-muted"))
      .navigationTitle("Calendars")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { isReorderActive.toggle() }) {
            Image(systemName: "arrow.up.arrow.down")
              .resizable()
              .frame(width: 16, height: 16)
              .foregroundColor(Color("text-tertiary"))

          }
        }
      }
    }
  }
}

struct ContextOrDragModifier: ViewModifier {
  let isReorderActive: Bool
  let calendar: CustomCalendar
  @ObservedObject var store: CustomCalendarStore
  @Binding var showEditSheet: Bool
  @Binding var showDeleteConfirmation: Bool

  func body(content: Content) -> some View {
    if isReorderActive {
      content
        .onDrag {
          NSItemProvider(object: calendar.id.uuidString as NSString)

          let vibration = UIImpactFeedbackGenerator(style: .light)
          vibration.impactOccurred()

          return NSItemProvider(object: calendar.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: CalendarDropDelegate(item: calendar, store: store))
    } else {
      content.contextMenu {
        Button(action: {
          showEditSheet = true
        }) {
          Text("Edit Calendar")
        }
        Divider()
        Button(action: {
          showDeleteConfirmation = true
        }) {
          Text("Delete Calendar")
        }
      }
    }
  }
}

struct CalendarDropDelegate: DropDelegate {
  let item: CustomCalendar
  @ObservedObject var store: CustomCalendarStore

  func performDrop(info: DropInfo) -> Bool {
    let providers = info.itemProviders(for: [.text])
    if let provider = providers.first {
      provider.loadObject(ofClass: NSString.self) { (object, error) in
        if let idString = object as? String, let draggedUUID = UUID(uuidString: idString) {
          DispatchQueue.main.async {
            if let sourceIndex = store.calendars.firstIndex(where: { $0.id == draggedUUID }),
              let targetIndex = store.calendars.firstIndex(where: { $0.id == item.id }),
              sourceIndex != targetIndex
            {
              let destination = targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
              withAnimation {
                store.moveCalendar(
                  fromOffsets: IndexSet(integer: sourceIndex), toOffset: destination)
              }
            }
          }
        }
      }
    }

    let vibration = UIImpactFeedbackGenerator(style: .light)
    vibration.impactOccurred()

    return true
  }
}

struct CalendarOverviewSheetItem: View {
  let calendar: CustomCalendar
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var store: CustomCalendarStore
  @State private var showDeleteConfirmation = false
  @State private var showEditSheet = false
  @Binding var isReorderActive: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Circle()
          .fill(Color(calendar.color))
          .frame(width: 12, height: 12)

        Text(calendar.name.capitalized)
          .font(.system(size: 18))
          .fontWeight(.bold)
          .foregroundColor(Color("text-primary"))
          .lineLimit(2)
          .minimumScaleFactor(0.5)
          .multilineTextAlignment(.leading)
      }

      Spacer()

      Text(calendar.trackingType.description)
        .font(.system(size: 11))
        .foregroundColor(Color("text-tertiary"))
        .lineLimit(2)
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding()
    .background(Color("surface-primary"))
    .cornerRadius(12)
    .aspectRatio(1.4, contentMode: .fit)
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
          })
      }
      .background(Color("surface-muted"))
    }
  }
}

struct ContentView: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var showingCreateSheet = false
  @State private var displayPaywall = false
  @State private var selectedIndex: Int = 0
  @State private var showingOverview = false
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
  @State private var dragStarted: Bool = false

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
        ForEach(Array(store.calendars.enumerated()), id: \.element.id) { index, calendar in
          CustomCalendarView(calendar: calendar)
            .tag(index + 2)
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
        DragGesture()
          .onChanged { value in
            if !dragStarted {
              dragStarted = true
              impactGenerator.impactOccurred()
            }
          }
          .onEnded { value in
            impactGenerator.impactOccurred()
            dragStarted = false
            if value.translation.height < -100 {
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
