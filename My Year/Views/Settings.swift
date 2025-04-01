import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true // Default to enabled
  @AppStorage("runtimeDebugEnabled") var runtimeDebugEnabled: Bool = false // Add new debug setting

  var body: some View {
    NavigationView { // Add NavigationView for title
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

        Form { // Use Form for settings layout
            Section(header: Text("Features")) {
                Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
                #if DEBUG
                Toggle("Enable Runtime Debug", isOn: $runtimeDebugEnabled) // Add conditional debug toggle
                #endif
            }
        }.font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color("text-secondary"))

        Spacer() // Push credits to the bottom

        // Credits Section
        VStack(spacing: 0) {
            Text("Independently engineered. Lovingly crafted.")
            Text("Thank you for your support!")

            Spacer().frame(height: 10) // Add some space before the name
            HStack(spacing: 4) {
                Text("Mykhaylo Tymofyeyev")
                Text("•")
                // Assuming you want the link here too, using a default color for now
                Text("[@tymofyeyev_m](https://x.com/tymofyeyev_m)").foregroundColor(.blue) 
            }
            .foregroundColor(Color("text-tertiary"))

        }
        .font(.system(size: 9, design: .monospaced))
        .foregroundColor(Color("text-tertiary").opacity(0.5))
        .multilineTextAlignment(.center)
      }
        .padding(.vertical, 20)
    }
  }
}

#Preview {
    SettingsView()
}
