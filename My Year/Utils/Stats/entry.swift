import SharedModels
import SwiftUI

func entry(for calendar: CustomCalendar, _ date: Date, store: CustomCalendarStore) -> CalendarEntry? {
  store.getEntry(calendarId: calendar.id, date: date)
}
