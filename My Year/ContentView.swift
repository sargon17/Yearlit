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

  var body: some View {
    AppRouter()
      .onAppear {
        Purchases.shared.getCustomerInfo { (customerInfo, _) in
          self.customerInfo = customerInfo
        }
        Task {
          await checkForNotificationsOfNonExistingCalendars(store: store)
        }
      }
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
}
