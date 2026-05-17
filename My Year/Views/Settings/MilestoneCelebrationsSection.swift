import SwiftUI

struct MilestoneCelebrationsSectionView: View {
  @AppStorage(AppStorageKeys.milestoneCelebrationsEnabled) private var milestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.streakMilestoneCelebrationsEnabled)
  private var streakMilestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.showedUpMilestoneCelebrationsEnabled)
  private var showedUpMilestoneCelebrationsEnabled: Bool = true
  @AppStorage(AppStorageKeys.recapMilestoneCelebrationsEnabled)
  private var recapMilestoneCelebrationsEnabled: Bool = false

  private var milestoneCelebrationsBinding: Binding<Bool> {
    Binding(
      get: { milestoneCelebrationsEnabled },
      set: { newValue in
        guard newValue != milestoneCelebrationsEnabled else { return }
        milestoneCelebrationsEnabled = newValue
        Analytics.shared.track(
          .milestoneCelebrationsEnabledChanged,
          properties: ["enabled": .bool(newValue)]
        )
      }
    )
  }

  private var streakMilestoneCelebrationsBinding: Binding<Bool> {
    Binding(
      get: { streakMilestoneCelebrationsEnabled },
      set: { newValue in
        guard newValue != streakMilestoneCelebrationsEnabled else { return }
        streakMilestoneCelebrationsEnabled = newValue
        Analytics.shared.track(
          .streakMilestoneCelebrationsEnabledChanged,
          properties: ["enabled": .bool(newValue)]
        )
      }
    )
  }

  private var showedUpMilestoneCelebrationsBinding: Binding<Bool> {
    Binding(
      get: { showedUpMilestoneCelebrationsEnabled },
      set: { newValue in
        guard newValue != showedUpMilestoneCelebrationsEnabled else { return }
        showedUpMilestoneCelebrationsEnabled = newValue
        Analytics.shared.track(
          .showedUpMilestoneCelebrationsEnabledChanged,
          properties: ["enabled": .bool(newValue)]
        )
      }
    )
  }

  private var recapMilestoneCelebrationsBinding: Binding<Bool> {
    Binding(
      get: { recapMilestoneCelebrationsEnabled },
      set: { newValue in
        guard newValue != recapMilestoneCelebrationsEnabled else { return }
        recapMilestoneCelebrationsEnabled = newValue
        Analytics.shared.track(
          .recapMilestoneCelebrationsEnabledChanged,
          properties: ["enabled": .bool(newValue)]
        )
      }
    )
  }

  var body: some View {
    Section(header: Text("Milestone celebrations")) {
      Toggle("Show milestone celebrations", isOn: milestoneCelebrationsBinding)

      Toggle("Streak celebrations", isOn: streakMilestoneCelebrationsBinding)
        .padding(.vertical, 2)
        .disabled(!milestoneCelebrationsEnabled)
      Toggle("Showing up celebrations", isOn: showedUpMilestoneCelebrationsBinding)
        .padding(.vertical, 2)
        .disabled(!milestoneCelebrationsEnabled)
      Toggle("Monthly & yearly recaps", isOn: recapMilestoneCelebrationsBinding)
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
