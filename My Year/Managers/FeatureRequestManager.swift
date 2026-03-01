import Combine
import Foundation
import Observation

private let baseURL = "https://qualified-viper-293.convex.site/api/"

final class FeatureRequestManager: ObservableObject {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
    static let keychainService = "com.tymofyeyev.yearlit.wish"
    static let keychainAccount = "feature-request-client-id"
  }

  private struct CreateCommentRequest: Codable {
    let body: String
    let clientId: String
  }

  private struct ToggleUpvoteRequest: Codable {
    let clientId: String
  }

  let appID: String
  private let defaults: UserDefaults
  var requests: FeatureRequestsListResponse?

  @Published private(set) var user: WishAppUser
  @Published private(set) var viewerUpvotes: Set<String> = []
  @Published private(set) var viewerUpvotesLoaded = false

  init(appID: String, defaults: UserDefaults = .standard) {
    self.appID = appID
    self.defaults = defaults

    let identifier = Self.loadOrCreateIdentifier(from: defaults)
    user = WishAppUser(id: identifier)
  }

  private static func loadOrCreateIdentifier(from defaults: UserDefaults) -> UUID {
    if let keychainValue = KeychainStore.read(
      account: Constants.keychainAccount,
      service: Constants.keychainService
    ),
      let keychainUUID = UUID(uuidString: keychainValue)
    {
      return keychainUUID
    }

    if let storedValue = defaults.string(forKey: Constants.userDefaultsKey),
      let storedUUID = UUID(uuidString: storedValue)
    {
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

    @Published private(set) var user: WishAppUser

    init(appID: String, defaults: UserDefaults = .standard) {
        self.appID = appID
        self.defaults = defaults

        let identifier = Self.loadOrCreateIdentifier(from: defaults)
        user = WishAppUser(id: identifier)
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

    func getUserId() -> String {
        return user.id.uuidString
    }

  func getViewerUpvotes() async -> Set<String> {
    let clientId = user.id.uuidString
    let endpoint =
      "\(baseURL)project/\(appID)/upvotes?clientId=\(clientId)"

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        type: FeatureRequestViewerUpvotesResponse.self
      )
      let upvotes = Set(response.upvotes)
      viewerUpvotes = upvotes
      viewerUpvotesLoaded = true
      return upvotes
    } catch {
      viewerUpvotesLoaded = true
      return viewerUpvotes
    }
  }

  func getComments(requestId: String) async -> [FeatureRequestComment] {
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comments"

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        type: FeatureRequestCommentsResponse.self
      )
      return response.comments.filter {
        !$0.body.isEmpty && ($0.isDeveloper || !$0.authorClientId.isEmpty)
      }
    } catch {
      return []
    }
  }

  func addComment(requestId: String, text: String) async -> [FeatureRequestComment] {
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comment"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        data: CreateCommentRequest(
          body: text,
          clientId: user.id.uuidString
        )
      )
    } catch {
      return []
    }

    return await getComments(requestId: requestId)
  }

  func deleteComment(requestId: String, comment: FeatureRequestComment) async -> Bool {
    guard isCurrentUser(id: comment.authorClientId) else { return false }

    let clientId = user.id.uuidString
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comment/\(comment.id)?clientId=\(clientId)"

    do {
      try await HTTP.delete(endpoint: endpoint)
      return true
    } catch {
      return false
    }
  }

  func toggleUpvote(requestId: String, wasUpvoted: Bool? = nil) async -> Bool {
    let currentWasUpvoted = wasUpvoted ?? viewerUpvotes.contains(requestId)
    let nextUpvoted = !currentWasUpvoted
    updateViewerUpvotes(requestId: requestId, isUpvoted: nextUpvoted)
    updateCachedUpvote(requestId: requestId, isUpvoted: nextUpvoted)

    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/upvote"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        data: ToggleUpvoteRequest(
          clientId: user.id.uuidString
        )
      )
      _ = await getViewerUpvotes()
      return true
    } catch {
      updateViewerUpvotes(requestId: requestId, isUpvoted: currentWasUpvoted)
      updateCachedUpvote(requestId: requestId, isUpvoted: currentWasUpvoted)
      return false
    }
  }

  private func updateViewerUpvotes(requestId: String, isUpvoted: Bool) {
    if isUpvoted {
      viewerUpvotes.insert(requestId)
    } else {
      viewerUpvotes.remove(requestId)
    }
  }

  private func updateCachedUpvote(requestId: String, isUpvoted: Bool) {
    guard var storedRequests = requests else { return }
    guard let index = storedRequests.requests.firstIndex(where: { $0.id == requestId }) else { return }

    let currentRequest = storedRequests.requests[index]
    let delta = isUpvoted ? 1 : -1
    let updatedCount = max((currentRequest.upvoteCount ?? 0) + delta, 0)
    let updatedRequest = Request(
      _id: currentRequest._id,
      _creationTime: currentRequest._creationTime,
      text: currentRequest.text,
      description: currentRequest.description,
      clientId: currentRequest.clientId,
      upvoteCount: updatedCount,
      status: currentRequest.status,
      project: currentRequest.project,
      computedStatus: currentRequest.computedStatus
    )
    storedRequests.requests[index] = updatedRequest
    requests = storedRequests
  }

  func createRequest(
    text: String,
    description: String?,
    onSuccess: (() -> Void)? = nil,
    onError: (() -> Void)? = nil
  ) async {
    do {
      try await HTTP.post(
        endpoint: "\(baseURL)project/\(appID)/request/",
        data: CreateRequest(
          text: text,
          description: description,
          clientId: user.id.uuidString,
          project: appID
        )
      )

      invalidateRequests()
      onSuccess?()
    } catch {
      onError?()
    }
}
