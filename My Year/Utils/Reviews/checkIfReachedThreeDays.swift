import SharedModels
import SwiftUI

func checkIfReachedThreeDays(_ calendar: CustomCalendar) {
  guard calendar.entries.count == 4 else { return }
  addPositiveEvent(.reachedThreeCompletedDays)
}
