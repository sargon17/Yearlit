import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = false  // Default to enabled
  @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false  // Add new debug setting
  @AppStorage("wandFillForce") var wandFillForce: Double = 0.5  // Default wand fill force

  var body: some View {
    VStack {  // Add NavigationView for title
      VStack(spacing: 0) {
        HStack {
          Text("Settings")
            .font(.system(size: 32, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(Color("text-primary"))
          Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)

        CustomSeparator()

        Form {  // Use Form for settings layout
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
        }.font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color("text-secondary"))

        Spacer()

        // Credits Section
        DevCredits()
      }
      .padding(.vertical, 20)
    }
  }
}

#Preview {
  SettingsView()
}
