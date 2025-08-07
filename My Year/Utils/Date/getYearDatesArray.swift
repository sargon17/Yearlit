import Foundation
import SwiftDate

public func getYearDatesArray() -> [Date] {
  let todayInRegion = DateInRegion()
  let startOfYear = todayInRegion.dateAtStartOf(.year)
  let endOfYear = todayInRegion.dateAtEndOf(.year)
  let increment = DateComponents.create { $0.day = 1 }
  let dateInRegions = DateInRegion.enumerateDates(from: startOfYear, to: endOfYear, increment: increment)
  return dateInRegions.map { $0.date }
}
