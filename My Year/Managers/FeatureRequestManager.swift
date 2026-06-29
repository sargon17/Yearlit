import Combine
import Foundation

@MainActor
final class FeatureRequestManager: ObservableObject {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
    static let keychainService = "com.tymofyeyev.yearlit.wish"
    static let keychainAccount = "feature-request-client-id"
  }

  private let config: WishConfiguration?
  private let defaults: UserDefaults
  var requests: FeatureRequestsListResponse?

  @Published private(set) var user: WishAppUser
  @Published private(set) var viewerUpvotes: Set<String> = []
  @Published private(set) var viewerUpvotesLoaded = false
  @Published private(set) var upvotesSupported = true

  init(config: WishConfiguration?, defaults: UserDefaults = .standard) {
    self.config = config
    self.defaults = defaults

    let identifier = Self.loadOrCreateIdentifier(from: defaults)
    user = WishAppUser(id: identifier)
  }

  var isConfigured: Bool {
    config != nil
  }

  var apiContext: FeatureRequestAPIContext? {
    guard let config else { return nil }
    return FeatureRequestAPIContext(
      baseURL: "\(config.baseURL)/api",
      projectID: config.projectID,
      headers: ["x-api-key": config.apiKey]
    )
  }

  func logError(_ message: String, error: Error? = nil) {
    #if DEBUG
      if let error {
        NSLog("Wish integration error: \(message) - \(error.localizedDescription)")
      } else {
        NSLog("Wish integration error: \(message)")
      }
    #endif
  }

  private static func loadOrCreateIdentifier(from defaults: UserDefaults) -> UUID {
    if let keychainValue = KeychainStore.read(
      account: Constants.keychainAccount,
      service: Constants.keychainService
    ),
      let keychainUUID = UUID(uuidString: keychainValue) {
      return keychainUUID
    }

    if let storedValue = defaults.string(forKey: Constants.userDefaultsKey),
      let storedUUID = UUID(uuidString: storedValue) {
      KeychainStore.save(
        value: storedUUID.uuidString,
        account: Constants.keychainAccount,
        service: Constants.keychainService
      )
      return storedUUID
    }

    let newUUID = UUID()
    defaults.set(newUUID.uuidString, forKey: Constants.userDefaultsKey)
    KeychainStore.save(
      value: newUUID.uuidString,
      account: Constants.keychainAccount,
      service: Constants.keychainService
    )
    return newUUID
  }

  func isCurrentUser(id: String) -> Bool {
    id == user.id.uuidString
  }

  func reloadRequests() async -> FeatureRequestsListResponse? {
    guard let apiContext else {
      logError("Missing configuration for request reload")
      return requests
    }

    let endpoint = apiContext.projectEndpoint("/requests/")
    do {
      let fetched = try await HTTP.get(
        endpoint: endpoint,
        headers: apiContext.headers,
        type: FeatureRequestsListResponse.self
      )
      requests = fetched
      return fetched
    } catch {
      logError("Failed to reload requests", error: error)
      return requests
    }
  }

  func getViewerUpvotes() async -> Set<String> {
    guard upvotesSupported else {
      viewerUpvotesLoaded = true
      return viewerUpvotes
    }

    guard let apiContext else {
      viewerUpvotesLoaded = true
      upvotesSupported = false
      logError("Missing configuration for viewer upvotes")
      return viewerUpvotes
    }

    let clientId = user.id.uuidString
    let endpoint = apiContext.projectEndpoint("/upvotes?clientId=\(clientId)")

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        headers: apiContext.headers,
        type: FeatureRequestViewerUpvotesResponse.self
      )
      let upvotes = Set(response.upvotes)
      viewerUpvotes = upvotes
      viewerUpvotesLoaded = true
      upvotesSupported = true
      return upvotes
    } catch {
      logError("Failed to fetch viewer upvotes", error: error)
      viewerUpvotesLoaded = true
      return viewerUpvotes
    }
  }

  func toggleUpvote(requestId: String, wasUpvoted: Bool? = nil) async -> Bool {
    guard upvotesSupported else {
      return false
    }
    guard let apiContext else {
      logError("Missing configuration for upvote toggle")
      return false
    }

    let currentWasUpvoted = wasUpvoted ?? viewerUpvotes.contains(requestId)
    let nextUpvoted = !currentWasUpvoted
    updateViewerUpvotes(requestId: requestId, isUpvoted: nextUpvoted)
    updateCachedUpvote(requestId: requestId, isUpvoted: nextUpvoted)

    let endpoint = apiContext.projectEndpoint("/request/\(requestId)/upvote")

    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: apiContext.headers,
        data: FeatureRequestToggleUpvoteRequest(
          clientId: user.id.uuidString
        )
      )
      _ = await getViewerUpvotes()
      return true
    } catch {
      logError("Failed to toggle upvote", error: error)
      updateViewerUpvotes(requestId: requestId, isUpvoted: currentWasUpvoted)
      updateCachedUpvote(requestId: requestId, isUpvoted: currentWasUpvoted)
      return false
    }
  }

  func updateViewerUpvotes(requestId: String, isUpvoted: Bool) {
    if isUpvoted {
      viewerUpvotes.insert(requestId)
    } else {
      viewerUpvotes.remove(requestId)
    }
  }

  func updateCachedUpvote(requestId: String, isUpvoted: Bool) {
    guard var storedRequests = requests else { return }
    guard let index = storedRequests.requests.firstIndex(where: { $0.id == requestId }) else { return }

    let currentRequest = storedRequests.requests[index]
    let delta = isUpvoted ? 1 : -1
    let nextCount = max(0, (currentRequest.upvoteCount ?? 0) + delta)
    storedRequests.requests[index] = currentRequest.withUpvoteCount(nextCount)
    requests = storedRequests
  }

}
