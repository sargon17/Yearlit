import SwiftUI

struct Features: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = false  // Default to enabled
  @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false  // Add new debug setting
  @AppStorage("wandFillForce") var wandFillForce: Double = 0.5  // Default wand fill force

  var body: some View {
    Section(header: Text("Features")) {
      Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
      #if DEBUG
        Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled)  // Add conditional debug toggle
        if runtimeDebugEnabled {
          VStack(alignment: .leading) {
            Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
            Slider(value: $wandFillForce, in: 0.0...1.0, step: 0.05)
          }
          Button("Reset What's New") {
            whatsNewManager.resetLastSeenVersion()
          }
        }
      #endif
    }
  }
}
