//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import SharedModels
import SwiftDate
import SwiftUI
import SwiftfulRouting

@main
// swiftlint:disable:next type_name
struct My_YearApp: App {

  #if DEBUG
    public static let isDebugMode = true
  #else
    public static let isDebugMode = false
  #endif

  init() {
    Purchases.configure(withAPIKey: "appl_rQKHOkYUqJKaipHpcSXlIpPgvPe")

    let appGroupId = "group.sargon17.My-Year"
    if let defaults = UserDefaults(suiteName: appGroupId) {
      NSLog("Successfully created UserDefaults with App Group: \(appGroupId)")

      let testKey = "appLaunchTest"
      defaults.set("test", forKey: testKey)
      defaults.synchronize()

      if let testValue = defaults.string(forKey: testKey) {
        NSLog("Successfully wrote and read test value: \(testValue)")
        defaults.removeObject(forKey: testKey)
      } else {
        NSLog("Failed to read test value!")
      }
    } else {
      NSLog("Failed to create UserDefaults with App Group!")
    }
  }

  var dates: [Date] {
    let todayInRegion = DateInRegion(region: .current)
    let startOfYear = todayInRegion.dateAtStartOf(.year)
    let endOfYear = todayInRegion.dateAtEndOf(.year)
    let increment = DateComponents.create { $0.day = 1 }
    let dateInRegions = DateInRegion.enumerateDates(from: startOfYear, to: endOfYear, increment: increment)
    return dateInRegions.map { $0.date }
  }

  var body: some Scene {
    WindowGroup {
      RouterView { _ in
        ContentView()
      }
      .environment(\.dates, dates)
      .onOpenURL { url in
        if url.scheme == "my-year" && url.host == "clear" {
          let store = ValuationStore.shared
          store.clearAllValuations()
        }
      }
    }
  }
}

struct DatesKey: EnvironmentKey {
  static let defaultValue: [Date] = []
}
extension EnvironmentValues {
  var dates: [Date] {
    get { self[DatesKey.self] }
    set { self[DatesKey.self] = newValue }
  }
}
