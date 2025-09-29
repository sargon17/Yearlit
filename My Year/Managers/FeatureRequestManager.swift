import Combine
import Foundation
import Observation

final class FeatureRequestManager: ObservableObject {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
  }

  let appID: String
  private let defaults: UserDefaults

  @Published private(set) var user: WishAppUser

  init(appID: String, defaults: UserDefaults = .standard) {
    self.appID = appID
    self.defaults = defaults

    let identifier = Self.loadOrCreateIdentifier(from: defaults)
    self.user = WishAppUser(id: identifier)
  }

  private static func loadOrCreateIdentifier(from defaults: UserDefaults) -> UUID {
    if let storedValue = defaults.string(forKey: Constants.userDefaultsKey),
      let storedUUID = UUID(uuidString: storedValue)
    {
      return storedUUID
    }

    let newUUID = UUID()
    defaults.set(newUUID.uuidString, forKey: Constants.userDefaultsKey)
    return newUUID
  }
}
