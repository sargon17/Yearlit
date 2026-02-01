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

struct ContentView: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var lastCleanupVersion: Int = -1
  @State private var cleanupTask: Task<Void, Never>?
  @EnvironmentObject private var whatsNewManager: WhatsNewManager

  var body: some View {
    AppRouter()
      .onAppear {
        Purchases.shared.getCustomerInfo { (customerInfo, _) in
          self.customerInfo = customerInfo
        }
        whatsNewManager.evaluateIfNeeded(
          hasCalendars: !store.calendars.isEmpty,
          isLoading: store.isLoading
        )
      }
      .onReceive(store.$calendars) { calendars in
        whatsNewManager.evaluateIfNeeded(
          hasCalendars: !calendars.isEmpty,
          isLoading: store.isLoading
        )
      }
      .onReceive(store.$isLoading) { isLoading in
        whatsNewManager.evaluateIfNeeded(
          hasCalendars: !store.calendars.isEmpty,
          isLoading: isLoading
        )
      }
      .onChange(of: store.dataVersion) { _, newVersion in
        // Debounce cleanup to avoid excessive IPC calls
        cleanupTask?.cancel()
        cleanupTask = Task {
          // Wait 2 seconds to batch multiple rapid changes
          try? await Task.sleep(for: .seconds(2))
          
          // Check if still needed and not cancelled
          guard !Task.isCancelled,
                lastCleanupVersion != newVersion else { return }
          
          lastCleanupVersion = newVersion
          await checkForNotificationsOfNonExistingCalendars(store: store)
        }
      }
      .task {
        // Initial cleanup on app launch
        await checkForNotificationsOfNonExistingCalendars(store: store)
      }
      .toolbarBackground(.hidden, for: .navigationBar)
      .font(.system(.body, design: .monospaced))
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
    .environmentObject(WhatsNewManager())
}
