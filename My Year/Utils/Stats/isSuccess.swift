import SharedModels
import SwiftUI

func isSuccess(
  for calendar: CustomCalendar,
  entry: CalendarEntry?
) -> Bool {
  guard let e = entry else { return false }
  switch calendar.trackingType {
  case .binary:
    return e.completed
  case .counter:
    return e.count > 0
  case .multipleDaily:
    return e.count >= calendar.dailyTarget
  }
}
