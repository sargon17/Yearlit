import SharedModels
import SwiftUI

func isEntrySuccess(_ entry: CalendarEntry?, calendar: CustomCalendar) -> Bool {
  guard let entry = entry else { return false }
  switch calendar.trackingType {
  case .binary:
    return entry.completed
  case .counter:
    return entry.count > 0
  case .multipleDaily:
    return entry.count >= calendar.dailyTarget
  }
}
