import SharedModels
import SwiftUI

func quickEntry(
  calendar: CustomCalendar,
  date: Date,
  calendarStore: CustomCalendarStore,
  valuationStore: ValuationStore
) {
  let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)
  var newEntry: CalendarEntry

  switch calendar.trackingType {
  case .binary:
    _ = toggleBinaryEntry(
      calendarId: calendar.id,
      date: today,
      calendarStore: calendarStore
    )
  case .counter, .multipleDaily:
    break
  }

  // Check if an entry already exists for today
  if let existingEntry = calendarStore.getEntry(calendarId: calendar.id, date: today) {
    // If the tracking type is counter or multipleDaily, increment the count by the defaultRecordValue
    if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
      let addValue = calendar.defaultRecordValue ?? 1  // Use defaultRecordValue or 1 if nil
      newEntry = CalendarEntry(
        date: today,
        count: existingEntry.count + addValue,
        completed: existingEntry.completed
      )

      calendarStore.addEntry(calendarId: calendar.id, entry: newEntry)
    }

  } else {
    // If no entry exists, create a new one using defaultRecordValue for count
    if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
      let addValue = calendar.defaultRecordValue ?? 1  // Use defaultRecordValue or 1 if nil
      newEntry = CalendarEntry(date: today, count: addValue, completed: addValue > 0)
      calendarStore.addEntry(calendarId: calendar.id, entry: newEntry)
    }
  }

}
