import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = false  // Default to enabled
  @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false  // Add new debug setting
  @AppStorage("wandFillForce") var wandFillForce: Double = 0.5  // Default wand fill force

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section(header: Text("Features")) {
          Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
          #if DEBUG
            Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled)  // Add conditional debug toggle
            if runtimeDebugEnabled {
              VStack(alignment: .leading) {
                Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
                Slider(value: $wandFillForce, in: 0.0...1.0, step: 0.05)
              }
            }
          #endif
        }

        About()
        Contacts()
        DevSupport()
      }
      .scrollContentBackground(.hidden)
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color("text-secondary"))
      DevCredits().padding(.top, 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Settings")

  }
}

#Preview {
  SettingsView()
}
