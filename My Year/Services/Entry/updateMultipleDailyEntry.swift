import SharedModels
import SwiftUI

func updateMultipleDailyEntry(
  calendar: CustomCalendar,
  date: Date,
  calendarStore: CustomCalendarStore,
  addValue: Int
) {
  var newEntry: CalendarEntry
  let calendarId = calendar.id

  if let entry = calendarStore.getEntry(calendarId: calendarId, date: date) {
    let newValue = entry.count + addValue
    let isCompleted = newValue >= calendar.dailyTarget

    newEntry = CalendarEntry(
      date: date,
      count: newValue,
      completed: isCompleted
    )
  } else {
    newEntry = defaultEntry(date: date, trackingType: .multipleDaily)
  }

  calendarStore.addEntry(calendarId: calendarId, entry: newEntry)
}
