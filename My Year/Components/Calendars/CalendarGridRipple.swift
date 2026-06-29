import Foundation

struct CalendarGridRipple {
  let delay: Double
  let intensity: Double
  let rotation: Double

  init(index: Int, originIndex: Int?, columns: Int) {
    guard let originIndex else {
      delay = 0
      intensity = 1
      rotation = Self.rotation(for: index)
      return
    }

    let distance = Self.distance(index: index, originIndex: originIndex, columns: columns)
    delay = (distance * 0.038) + ((sin(Double(index) * 12.9898) + 1) * 0.024)
    intensity = max(0.28, 1 - (distance * 0.075))
    rotation = Self.rotation(for: index)
  }

  private static func distance(index: Int, originIndex: Int, columns: Int) -> Double {
    let row = index / columns
    let column = index % columns
    let originRow = originIndex / columns
    let originColumn = originIndex % columns
    return hypot(Double(row - originRow), Double(column - originColumn))
  }

  private static func rotation(for index: Int) -> Double {
    sin(Double(index) * 78.233) >= 0 ? 7 : -7
  }
}
