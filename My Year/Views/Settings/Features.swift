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

    private var moodTrackingBinding: Binding<Bool> {
        Binding(
            get: { isMoodTrackingEnabled },
            set: { newValue in
                guard newValue != isMoodTrackingEnabled else { return }
                isMoodTrackingEnabled = newValue
                Analytics.shared.track(.moodTrackingEnabledChanged, properties: ["enabled": .bool(newValue)])
            }
        )
    }

    private var recapViewBinding: Binding<Bool> {
        Binding(
            get: { isRecapViewEnabled },
            set: { newValue in
                guard newValue != isRecapViewEnabled else { return }
                isRecapViewEnabled = newValue
                Analytics.shared.track(.recapViewEnabledChanged, properties: ["enabled": .bool(newValue)])
            }
        )
    }

    var body: some View {
        Section(header: Text("Features")) {
            Toggle("Enable Mood Tracking", isOn: moodTrackingBinding)
            Toggle("Enable Recap View", isOn: recapViewBinding)

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
