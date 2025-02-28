//
//  HabitsWidgetControl.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import AppIntents
import SharedModels
import SwiftUI
import WidgetKit

struct HabitsWidgetControl: ControlWidget {
  static let kind: String = "sargon17.My-Year.HabitsWidget"

  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: Self.kind,
      provider: Provider()
    ) { value in
      ControlWidgetToggle(
        "Start Timer",
        isOn: value.isRunning,
        action: StartTimerIntent(value.name)
      ) { isRunning in
        Label(isRunning ? "On" : "Off", systemImage: "timer")
      }
    }
    .displayName("Timer")
    .description("A an example control that runs a timer.")
  }
}

extension HabitsWidgetControl {
  struct Value {
    var isRunning: Bool
    var name: String
  }

  struct Provider: AppIntentControlValueProvider {
    func previewValue(configuration: TimerConfiguration) -> Value {
      HabitsWidgetControl.Value(isRunning: false, name: configuration.timerName)
    }

    func currentValue(configuration: TimerConfiguration) async throws -> Value {
      let isRunning = true  // Check if the timer is running
      return HabitsWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
    }
  }
}

struct TimerConfiguration: ControlConfigurationIntent {
  static let title: LocalizedStringResource = "Timer Name Configuration"

  @Parameter(title: "Timer Name", default: "Timer")
  var timerName: String
}

struct StartTimerIntent: SetValueIntent {
  static let title: LocalizedStringResource = "Start a timer"

  @Parameter(title: "Timer Name")
  var name: String

  @Parameter(title: "Timer is running")
  var value: Bool

  init() {}

  init(_ name: String) {
    self.name = name
  }

  func perform() async throws -> some IntentResult {
    // Start the timer…
    return .result()
  }
}
