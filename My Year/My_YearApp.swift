//
//  My_YearApp.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import SwiftUI
import SharedModels

@main
struct My_YearApp: App {
    init() {
        NSLog("=== App Launch ===")
        NSLog("🚀 APP STARTING - IF YOU SEE THIS, LOGS ARE WORKING!")
        
        // Test direct UserDefaults access
        let appGroupId = "group.sargon17.My-Year"
        if let defaults = UserDefaults(suiteName: appGroupId) {
            NSLog("Successfully created UserDefaults with App Group: \(appGroupId)")
            
            // Try writing and reading a test value
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
        NSLog("==================")
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
