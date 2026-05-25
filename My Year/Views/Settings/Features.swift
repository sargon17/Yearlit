import SharedModels
import SwiftUI

struct YearExperienceSection: View {
  @ObservedObject private var timelinePreference = TimelinePreferenceManager.shared
  @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
  @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false

  private var selectedMode: Binding<CalendarTimelineMode> {
    Binding(
      get: { timelinePreference.mode },
      set: { timelinePreference.setMode($0) }
    )
  }

  private var timelineHelperCopy: String {
    String(localized: "Your 365 starts each daily habit from the day you began. Calendar Year shows January to December progress.")
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
    Section(header: Text("Your Year")) {
      Picker("Default year view", selection: selectedMode) {
        ForEach(CalendarTimelineMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.inline)

      Text(timelineHelperCopy)
        .font(.footnote)
        .foregroundStyle(.secondary)

      Toggle("Mood Tracking", isOn: moodTrackingBinding)
      Toggle("Recap View", isOn: recapViewBinding)
    }
  }
}

struct DeveloperSettingsSection: View {
  @AppStorage(AppStorageKeys.isDeveloperModeEnabled) var isDeveloperModeEnabled: Bool = false
  @AppStorage(AppStorageKeys.runtimeDebugEnabled) var runtimeDebugEnabled: Bool = false
  @AppStorage(AppStorageKeys.wandFillForce) var wandFillForce: Double = 0.5

  private var shouldShowDeveloperSettings: Bool {
    My_YearApp.isDebugMode || isDeveloperModeEnabled
  }

  private var shouldShowWandSettings: Bool {
    (My_YearApp.isDebugMode && runtimeDebugEnabled) || isDeveloperModeEnabled
  }

  var body: some View {
    if shouldShowDeveloperSettings {
      Section(header: Text("Developer")) {
        #if DEBUG
          Toggle("Runtime Debug", isOn: $runtimeDebugEnabled)
        #endif

        if shouldShowWandSettings {
          VStack(alignment: .leading, spacing: 8) {
            Text("Wand Fill Force: \(wandFillForce, specifier: "%.2f")")
            Slider(value: $wandFillForce, in: 0.0...1.0, step: 0.05)

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
}
