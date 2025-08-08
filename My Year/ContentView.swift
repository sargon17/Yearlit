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
import SwiftfulRouting
import UIKit

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
    Task {
      await hapticFeedback()
    }
    return true
  }
}

struct ContentView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var selectedIndex: Int = 1
  @ObservedObject private var valuationStore = ValuationStore.shared

  @Environment(\.router) private var router

  var body: some View {
    VStack {
      TabView(
        selection: $selectedIndex.onChange { _ in
          Task {
            await hapticFeedback()
          }
        }
      ) {
        // Year Grid
        if isMoodTrackingEnabled {
          MoodTrackingCalendar()
            .tag(-10)
        }

        AllCalendarsRecapView()
          .tag(0)

        // Custom Calendars
        ForEach(Array(store.calendars.enumerated()), id: \.element.id) { index, calendar in
          CustomCalendarView(calendar: calendar)
            .tag(index + 1)
        }

        // Add Calendar Button
        VStack {
          Spacer()
          VStack(spacing: 16) {
            Image(systemName: "plus")
              .font(.system(size: 42))
              .foregroundStyle(Color("text-tertiary"))
            Text("Add Calendar")
              .font(.headline)
              .foregroundColor(Color("text-primary"))
          }
          Spacer()
        }
        .tag(store.calendars.count + 3)
        .onTapGesture {
          router.showScreen(.sheet) { _ in
            CreateCalendarView { newCalendar in
              store.addCalendar(newCalendar)
              selectedIndex = store.calendars.count
              router.dismissScreen()
            }
          }
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
      .overlay {
        HStack {
          Text("Yearlit")
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("text-tertiary"))

          if customerInfo?.entitlements["premium"]?.isActive ?? false {
            Image(systemName: "checkmark.seal.fill")
              .font(.caption)
              .foregroundColor(Color("mood-excellent"))
              .shadow(color: Color("mood-excellent").opacity(0.5), radius: 10)
          }
        }.position(x: 50, y: -30)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: 4) {
            Button(action: {
              router.showScreen(.sheet) { _ in
                SettingsView()
              }
            }) {
              Image(systemName: "gearshape")
                .foregroundColor(Color("text-tertiary"))
                .font(.system(size: 12))
            }
            Button(action: {
              router.showScreen(.sheet) { _ in
                CalendarsOverview(store: store, valuationStore: valuationStore, selectedIndex: $selectedIndex)
              }
            }) {
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
      Task {
        await checkForNotificationsOfNonExistingCalendars(store: store)
      }
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
