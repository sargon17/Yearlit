import SharedModels
import SwiftUI

func defaultEntry(date: Date, trackingType: TrackingType) -> CalendarEntry {
  switch trackingType {
  case .counter:
    return CalendarEntry(date: date, count: 1, completed: true)
  case .multipleDaily:
    return CalendarEntry(date: date, count: 1, completed: false)
  case .binary:
    return CalendarEntry(date: date, count: 1, completed: true)
  }
}
