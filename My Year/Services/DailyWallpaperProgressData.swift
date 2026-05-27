import Foundation
import SharedModels

struct DailyWallpaperProgressData {
  let year: Int
  let currentDayNumber: Int
  let numberOfDaysInYear: Int

  var daysLeft: Int {
    numberOfDaysInYear - currentDayNumber
  }

  var percentComplete: Double {
    Double(currentDayNumber) / Double(numberOfDaysInYear)
  }

  init(referenceDate: Date, calendar: Calendar = LocalDayCalendar.calendar) {
    year = calendar.component(.year, from: referenceDate)
    currentDayNumber = Self.currentDayNumber(year: year, referenceDate: referenceDate, calendar: calendar)
    numberOfDaysInYear = Self.numberOfDaysInYear(year: year, calendar: calendar)
  }

  private static func currentDayNumber(year: Int, referenceDate: Date, calendar: Calendar) -> Int {
    let today = calendar.startOfDay(for: referenceDate)
    guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
      return 0
    }
    return (calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0) + 1
  }

  private static func numberOfDaysInYear(year: Int, calendar: Calendar) -> Int {
    let startOfYear = DateComponents(year: year, month: 1, day: 1)
    let endOfYear = DateComponents(year: year, month: 12, day: 31)
    guard let startDate = calendar.date(from: startOfYear),
      let endDate = calendar.date(from: endOfYear)
    else {
      return 365
    }

    return (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 364) + 1
  }
}
