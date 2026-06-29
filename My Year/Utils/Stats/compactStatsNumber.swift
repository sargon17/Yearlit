import Foundation

func compactStatsNumber(_ value: Int) -> String {
  let sign = value < 0 ? "-" : ""
  var number = value == Int.min ? Double(Int.max) + 1 : Double(abs(value))
  let units = ["", "K", "M", "B"]
  var unitIndex = 0

  while number >= 1_000, unitIndex < units.count - 1 {
    number /= 1_000
    unitIndex += 1
  }

  guard unitIndex > 0 else {
    return "\(value)"
  }

  var rounded = (number * 10).rounded() / 10
  if rounded >= 1_000, unitIndex < units.count - 1 {
    rounded /= 1_000
    unitIndex += 1
  }

  let text =
    rounded >= 100 || rounded.rounded() == rounded
    ? String(format: "%.0f", rounded)
    : String(format: "%.1f", rounded)
  return "\(sign)\(text)\(units[unitIndex])"
}
