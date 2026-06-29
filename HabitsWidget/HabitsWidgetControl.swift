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
            let calendars = CustomCalendarStore.fetchCalendarsSnapshot()

            guard
                let calendar = calendars.first(where: { $0.id.uuidString == configuration.calendarId })
            else {
                return Value(isCompleted: false, calendarId: configuration.calendarId)
            }

            let isCompleted = calendar.entry(for: Date())?.completed ?? false

            return Value(isCompleted: isCompleted, calendarId: configuration.calendarId)
        }
    }
}

struct HabitConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Habit Configuration"

    @Parameter(title: "Calendar ID", default: "default")
    var calendarId: String
}
