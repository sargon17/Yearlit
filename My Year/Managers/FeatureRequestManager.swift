import Combine
import Foundation
import Observation

private let baseURL = "https://qualified-viper-293.convex.site/api/"

final class FeatureRequestManager: ObservableObject {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
  }

  let appID: String
  private let defaults: UserDefaults
  var requests: FeatureRequestsListResponse?

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

  public func getUserId() -> String {
    return self.user.id.uuidString
  }

  public func isCurrentUser(id: String) -> Bool {
    return id == getUserId()
  }

  // returns the requests with a layer of caching (will not update the already saved requests in any case)
  public func getRequests() async -> FeatureRequestsListResponse? {
    if requests != nil {
      return requests
    } else {
      await fetchRequests()
      return await getRequests()
    }
  }

  public func reloadRequests() async -> FeatureRequestsListResponse? {
    await fetchRequests()
    return requests
  }

  public func invalidateRequests() {
    print("⚠️ invalidating requests")
    requests = nil
  }

  // fetch request from the server
  func fetchRequests() async {
    let endpoint =
      "\(baseURL)project/\(appID)/requests/"

    do {
      requests = try await HTTP.get(
        endpoint: endpoint,
        type: FeatureRequestsListResponse
          .self
      )
    } catch {
      print("error")
    }
  }

  public func deleteRequest(id: String) async {
    let endpoint =
      "\(baseURL)project/\(appID)/request/delete/\(id)"

    do {
      try await HTTP.delete(endpoint: endpoint)
      invalidateRequests()
    } catch {
      print("error")
    }
  }

}
