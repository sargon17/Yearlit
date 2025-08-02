import SharedModels
import SwiftUI

func updateCounterEntry(
  calendarId: UUID,
  date: Date,
  calendarStore: CustomCalendarStore,
  addValue: Int
) {
  var newEntry: CalendarEntry

  if let entry = calendarStore.getEntry(calendarId: calendarId, date: date) {
    let newValue = entry.count + addValue
    let isCompleted = newValue > 0
    newEntry = CalendarEntry(
      date: date,
      count: newValue,
      completed: isCompleted
    )
  } else {
    newEntry = defaultEntry(date: date, trackingType: .counter)
  }

  calendarStore.addEntry(calendarId: calendarId, entry: newEntry)
}
