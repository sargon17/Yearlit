import SwiftUI

struct SettingsView: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true // Default to enabled

  var body: some View {
    NavigationView { // Add NavigationView for title
      VStack {
        Form { // Use Form for settings layout
            Section(header: Text("Features")) {
                Toggle("Enable Mood Tracking", isOn: $isMoodTrackingEnabled)
            }
        }

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
        .padding(.bottom, 20) // Adjusted padding
      }
      .navigationTitle("Settings") // Set the title
    }
  }
}

#Preview {
    SettingsView()
}
