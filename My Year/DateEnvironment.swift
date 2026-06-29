import Foundation
import SwiftUI

struct DatesKey: EnvironmentKey {
  static let defaultValue: [Date] = []
}

extension EnvironmentValues {
  var dates: [Date] {
    get { self[DatesKey.self] }
    set { self[DatesKey.self] = newValue }
  }
}
