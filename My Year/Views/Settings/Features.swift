import SwiftUI

struct Features: View {
    @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
    @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false
    @AppStorage(AppStorageKeys.milestoneCelebrationsEnabled) var milestoneCelebrationsEnabled: Bool =
        true
    @AppStorage(AppStorageKeys.streakMilestoneCelebrationsEnabled) var streakMilestoneCelebrationsEnabled: Bool =
        true
    @AppStorage(AppStorageKeys.showedUpMilestoneCelebrationsEnabled) var showedUpMilestoneCelebrationsEnabled: Bool =
        true
    @AppStorage(AppStorageKeys.recapMilestoneCelebrationsEnabled) var recapMilestoneCelebrationsEnabled: Bool =
        false
    @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false
    @AppStorage("wandFillForce") var wandFillForce: Double = 0.5

    var body: some View {
        Section(header: Text("Features")) {
            Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
            Toggle("Enable Recap View", isOn: $isRecapViewEnabled)
            Toggle("Enable Milestone Celebrations", isOn: $milestoneCelebrationsEnabled)

            VStack(alignment: .leading, spacing: 8) {
                Toggle(
                    "Enable Streak Milestone Celebrations",
                    isOn: $streakMilestoneCelebrationsEnabled
                )
                Toggle(
                    "Enable Showed-Up Milestone Celebrations",
                    isOn: $showedUpMilestoneCelebrationsEnabled
                )
                Toggle(
                    "Enable Recap Milestone Celebrations",
                    isOn: $recapMilestoneCelebrationsEnabled
                )
            }
            .disabled(!milestoneCelebrationsEnabled)

            #if DEBUG
                Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled)
                if runtimeDebugEnabled {
                    VStack(alignment: .leading) {
                        Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
                        Slider(value: $wandFillForce, in: 0.0 ... 1.0, step: 0.05)
                    }
                }
            #endif
        }
    }
}
