import SwiftUI

struct Features: View {
    @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
    @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false
    @AppStorage(AppStorageKeys.isDeveloperModeEnabled) var isDeveloperModeEnabled: Bool = false
    @AppStorage(AppStorageKeys.runtimeDebugEnabled) var runtimeDebugEnabled: Bool = false
    @AppStorage(AppStorageKeys.wandFillForce) var wandFillForce: Double = 0.5

    private var shouldShowWandSettings: Bool {
        (My_YearApp.isDebugMode && runtimeDebugEnabled) || isDeveloperModeEnabled
    }

    var body: some View {
        Section(header: Text("Features")) {
            Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
            Toggle("Enable Recap View", isOn: $isRecapViewEnabled)

            #if DEBUG
                Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled)
            #endif

            if shouldShowWandSettings {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
                    Slider(value: $wandFillForce, in: 0.0 ... 1.0, step: 0.05)

                    if isDeveloperModeEnabled {
                        Button("Disable Developer Mode") {
                            isDeveloperModeEnabled = false
                        }
                        .foregroundColor(Color("text-tertiary"))
                    }
                }
            }
        }
    }
}
