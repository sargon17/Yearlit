//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import RevenueCat
import SharedModels
import SwiftUI

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

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL { url in
          if url.scheme == "my-year" && url.host == "clear" {
            let store = ValuationStore.shared
            store.clearAllValuations()
          }
        }
    }
  }
}
