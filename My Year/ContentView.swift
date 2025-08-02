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

struct ContentView: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var showingCreateSheet = false
  @State private var selectedIndex: Int = 0
  @State private var showingOverview = false
  @ObservedObject private var valuationStore = ValuationStore.shared
  private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
  @State private var dragStarted: Bool = false
  @State private var isSettingsPresented = false

  var body: some View {
    NavigationStack {
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
          showingCreateSheet = true
        }
      }.overlay {
        // Upper separator
        VStack {
          CustomSeparator()
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .ignoresSafeArea(edges: .bottom)
      .indexViewStyle(.page(backgroundDisplayMode: .never))
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          HStack(spacing: 4) {
            Text("Yearlit")
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("text-tertiary"))

            if customerInfo?.entitlements["premium"]?.isActive ?? false {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(Color("mood-excellent"))
                .shadow(color: Color("mood-excellent").opacity(0.5), radius: 10)
            }
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: 4) {
            Button(action: { isSettingsPresented = true }) {
              Image(systemName: "gearshape")
                .foregroundColor(Color("text-tertiary"))
                .font(.system(size: 12))
            }
            Button(action: { showingOverview = true }) {
              Image(systemName: "square.grid.2x2")
                .font(.system(size: 12))
                .foregroundColor(Color("text-tertiary"))
            }
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
      NavigationStack {
        CreateCalendarView { newCalendar in
          store.addCalendar(newCalendar)
          selectedIndex = store.calendars.count
          showingCreateSheet = false
        }
        .background(Color("surface-muted"))
      }
      .background(Color("surface-muted"))
    }
    .sheet(isPresented: $showingOverview) {
      CalendarsOverview(store: store, valuationStore: valuationStore, selectedIndex: $selectedIndex)
    }
    .sheet(isPresented: $isSettingsPresented) {
      SettingsView()
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
