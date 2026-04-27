import Foundation

enum Formatters {
  static let integer: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.minimum = 0
    return formatter
  }()

  static let positiveInteger: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.minimum = 1
    return formatter
  }()
}
