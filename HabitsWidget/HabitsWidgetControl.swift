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
  static let kind: String = "HabitsWidgetControl"

  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: Self.kind,
      provider: Provider()
    ) { value in
      ControlWidgetButton(
        "Quick Add",
        action: HabitQuickAddIntent(calendarId: value.calendarId)
      ) { _ in
        Label("Quick Add", systemImage: "plus.circle")
      }
    }
    .displayName("Habit Quick Add")
    .description("Quickly add entries to your habit tracker.")
  }
}

extension HabitsWidgetControl {
  struct Value {
    var isCompleted: Bool
    var calendarId: String
  }

  struct Provider: AppIntentControlValueProvider {
    func previewValue(configuration: HabitConfiguration) -> Value {
      HabitsWidgetControl.Value(isCompleted: false, calendarId: configuration.calendarId)
    }

    func currentValue(configuration: HabitConfiguration) async throws -> Value {
      let store = CustomCalendarStore.shared
      store.loadCalendars()

      guard
        let calendar = store.calendars.first(where: { $0.id.uuidString == configuration.calendarId }
        )
      else {
        return Value(isCompleted: false, calendarId: configuration.calendarId)
      }

      let valStore = ValuationStore.shared
      let today = valStore.dateForDay(valStore.currentDayNumber - 1)
      let isCompleted = store.getEntry(calendarId: calendar.id, date: today)?.completed ?? false

      return Value(isCompleted: isCompleted, calendarId: configuration.calendarId)
    }
  }
}

struct HabitConfiguration: ControlConfigurationIntent {
  static let title: LocalizedStringResource = "Habit Configuration"

  @Parameter(title: "Calendar ID", default: "default")
  var calendarId: String
}

// struct HabitQuickAddIntent: SetValueIntent {
//   static let title: LocalizedStringResource = "Quick Add Habit Entry"

//   @Parameter(title: "Calendar ID")
//   var calendarId: String

//   @Parameter(title: "Habit is completed")
//   var value: Bool

//   init() {
//     self.calendarId = ""
//     self.value = false
//   }

//   init(calendarId: String) {
//     self.calendarId = calendarId
//     self.value = false
//   }

//   func perform() async throws -> some IntentResult {
//     let store = CustomCalendarStore.shared
//     let valStore = ValuationStore.shared

//     guard let calendar = store.calendars.first(where: { $0.id.uuidString == calendarId }) else {
//       return .result()
//     }

//     let today: Date = Date()
//     var newEntry: CalendarEntry? = nil

//     if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
//       if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
//         newEntry = CalendarEntry(
//           date: today,
//           count: existingEntry.count + 1,
//           completed: false
//         )
//       } else {
//         newEntry = CalendarEntry(
//           date: today,
//           count: 1,
//           completed: !existingEntry.completed
//         )
//       }
//     }

//     do {
//       if let newEntry = newEntry {
//         try store.addEntry(calendarId: calendar.id, entry: newEntry)
//       }
//     } catch {
//       print(
//         "Error adding entry: \(error) \(newEntry ?? CalendarEntry(date: today, count: 1, completed: false))"
//       )
//       return .result()
//     }

//     return .result()
//   }
// }
