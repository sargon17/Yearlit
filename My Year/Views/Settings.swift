import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true // Default to enabled

  var body: some View {
    NavigationView { // Add NavigationView for title
        Form { // Use Form for settings layout
            Section(header: Text("Features")) {
                Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
            }
        }
        .navigationTitle("Settings") // Set the title
    }
  }
}

#Preview {
    SettingsView()
}
