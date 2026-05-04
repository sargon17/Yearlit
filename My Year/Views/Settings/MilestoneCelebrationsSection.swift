import SwiftUI

struct MilestoneCelebrationsSectionView: View {
  @AppStorage(AppStorageKeys.milestoneCelebrationsEnabled) private var milestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.streakMilestoneCelebrationsEnabled)
  private var streakMilestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.showedUpMilestoneCelebrationsEnabled)
  private var showedUpMilestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.recapMilestoneCelebrationsEnabled)
  private var recapMilestoneCelebrationsEnabled: Bool = false

  var body: some View {
    Section(header: Text("Milestone celebrations")) {
      Toggle("Show milestone celebrations", isOn: $milestoneCelebrationsEnabled)

      Toggle("Streak celebrations", isOn: $streakMilestoneCelebrationsEnabled)
        .padding(.vertical, 2)
        .disabled(!milestoneCelebrationsEnabled)
      Toggle("Showing up celebrations", isOn: $showedUpMilestoneCelebrationsEnabled)
        .padding(.vertical, 2)
        .disabled(!milestoneCelebrationsEnabled)
      Toggle("Monthly & yearly recaps", isOn: $recapMilestoneCelebrationsEnabled)
        .padding(.vertical, 2)
        .disabled(!milestoneCelebrationsEnabled)
    }
  }
}

#Preview {
  Form {
    MilestoneCelebrationsSectionView()
  }
}
