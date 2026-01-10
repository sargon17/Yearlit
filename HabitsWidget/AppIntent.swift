//
//  AppIntent.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import SharedModels

typealias ConfigurationAppIntent = CalendarWidgetConfigurationIntent

// public struct QuickAddIntent: AppIntent, SetValueIntent {
//   public static var title: LocalizedStringResource = "Quick Add Entry"
//   public static var description = IntentDescription("Quickly add an entry to your habit tracker")

//   @Parameter(title: "Calendar ID")
//   public var calendarId: String

//   public init() {
//     self.calendarId = ""
//   }

//   public init(calendarId: String) {
//     self.calendarId = calendarId
//   }

//   public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
//     let store = CustomCalendarStore.shared
//     let valStore = ValuationStore.shared

//     guard let calendar = store.calendars.first(where: { $0.id.uuidString == calendarId }) else {
//       return .result(value: false)
//     }

//     let today = valStore.dateForDay(valStore.currentDayNumber - 1)
//     var newEntry = CalendarEntry(date: today, count: 1, completed: true)

//     if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
//       if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
//         newEntry = CalendarEntry(
//           date: today,
//           count: existingEntry.count + 1,
//           completed: existingEntry.completed
//         )
//       } else {
//         newEntry = CalendarEntry(
//           date: today,
//           count: 1,
//           completed: !existingEntry.completed
//         )
//       }
//     }

//     store.addEntry(calendarId: calendar.id, entry: newEntry)
//     WidgetCenter.shared.reloadTimelines(ofKind: "HabitsWidget")
//     return .result(value: true)
//   }
// }
