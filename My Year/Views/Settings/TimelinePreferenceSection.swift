import SharedModels
import SwiftUI

struct TimelinePreferenceSection: View {
  @ObservedObject private var timelinePreference = TimelinePreferenceManager.shared

  private var selectedMode: Binding<CalendarTimelineMode> {
    Binding(
      get: { timelinePreference.mode },
      set: { timelinePreference.setMode($0) }
    )
  }

  private var helperCopy: String {
    "Your 365 starts each daily habit from the day you began. Calendar Year shows January to December progress."
  }

  var body: some View {
    Section(header: Text("Timeline")) {
      Picker("Default year view", selection: selectedMode) {
        ForEach(CalendarTimelineMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .pickerStyle(.inline)

      Text(helperCopy)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  Form {
    TimelinePreferenceSection()
  }
}
