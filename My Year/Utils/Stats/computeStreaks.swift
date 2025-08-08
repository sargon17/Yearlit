import SwiftUI

func computeStreaks(_ anySuccessByDay: [Date: Bool]) -> (longest: Int, current: Int) {
  let sortedDays = anySuccessByDay.keys.sorted()
  var longest = 0
  var temp = 0
  for day in sortedDays {
    if anySuccessByDay[day] == true {
      temp += 1
      longest = max(longest, temp)
    } else {
      temp = 0
    }
  }
  var current = 0
  for day in sortedDays.reversed() {
    if anySuccessByDay[day] == true { current += 1 } else { break }
  }
  return (longest, current)
}
