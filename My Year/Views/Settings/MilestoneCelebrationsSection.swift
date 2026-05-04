import SwiftUI

struct MilestoneCelebrationsSectionView: View {
    @AppStorage(AppStorageKeys.milestoneCelebrationsEnabled) private var milestoneCelebrationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.streakMilestoneCelebrationsEnabled)
    private var streakMilestoneCelebrationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.showedUpMilestoneCelebrationsEnabled)
    private var showedUpMilestoneCelebrationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.recapMilestoneCelebrationsEnabled) private var recapMilestoneCelebrationsEnabled: Bool =
        false

    var body: some View {
        Section(header: Text("Milestone celebrations")) {
            Toggle("Show milestone celebrations", isOn: $milestoneCelebrationsEnabled)

            Text("When celebrations are off, milestones are still remembered silently")
                + Text(" so you do not get catch-up popups later.")

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Streak celebrations", isOn: $streakMilestoneCelebrationsEnabled)
                Toggle("Showing up celebrations", isOn: $showedUpMilestoneCelebrationsEnabled)
                Toggle("Monthly & yearly recaps", isOn: $recapMilestoneCelebrationsEnabled)
            }
            .disabled(!milestoneCelebrationsEnabled)
        }
    }
}

#Preview {
    Form {
        MilestoneCelebrationsSectionView()
    }
}
