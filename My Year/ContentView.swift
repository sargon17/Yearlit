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
      .task(id: store.dataVersion) {
        guard lastCleanupVersion != store.dataVersion else { return }
        lastCleanupVersion = store.dataVersion
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
