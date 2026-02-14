import Combine
import Foundation
import Observation

private let baseURL = "https://qualified-viper-293.convex.site/api/"

final class FeatureRequestManager: ObservableObject {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
  }

  private struct CreateCommentRequest: Codable {
    let text: String
    let clientId: String
  }

  private struct ToggleUpvoteRequest: Codable {
    let requestId: String
    let clientId: String
  }

  let appID: String
  private let defaults: UserDefaults
  var requests: FeatureRequestsListResponse?

  @Published private(set) var user: WishAppUser
  @Published private(set) var viewerUpvotes: Set<String> = []

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

  func isCurrentUser(id: String) -> Bool {
    return id == getUserId()
  }

  // returns the requests with a layer of caching (will not update the already saved requests in any case)
  func getRequests() async -> FeatureRequestsListResponse? {
    if requests != nil {
      return requests
    } else {
      await fetchRequests()
      return await getRequests()
    }
  }

  func reloadRequests() async -> FeatureRequestsListResponse? {
    await fetchRequests()
    return requests
  }

  func invalidateRequests() {
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

  func deleteRequest(id: String) async {
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(id)"

    do {
      try await HTTP.delete(endpoint: endpoint)
      invalidateRequests()
    } catch {
      print("error")
    }
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
      return upvotes
    } catch {
      return viewerUpvotes
    }
  }

  func getComments(requestId: String) async -> [FeatureRequestComment] {
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comments/"

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        type: FeatureRequestCommentsResponse.self
      )
      return response.comments
    } catch {
      return []
    }
  }

  func addComment(requestId: String, text: String) async -> [FeatureRequestComment] {
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comments/"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        data: CreateCommentRequest(
          text: text,
          clientId: user.id.uuidString
        )
      )
    } catch {
      return []
    }

    return await getComments(requestId: requestId)
  }

  func deleteComment(requestId: String, comment: FeatureRequestComment) async -> Bool {
    guard isCurrentUser(id: comment.clientId) else { return false }

    let clientId = user.id.uuidString
    let endpoint =
      "\(baseURL)project/\(appID)/request/\(requestId)/comments/\(comment.id)?clientId=\(clientId)"

    do {
      try await HTTP.delete(endpoint: endpoint)
      return true
    } catch {
      return false
    }
  }

  func toggleUpvote(requestId: String) async -> Bool {
    let wasUpvoted = viewerUpvotes.contains(requestId)
    let nextUpvoted = !wasUpvoted
    updateViewerUpvotes(requestId: requestId, isUpvoted: nextUpvoted)
    updateCachedUpvote(requestId: requestId, isUpvoted: nextUpvoted)

    let endpoint =
      "\(baseURL)project/\(appID)/upvote/"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        data: ToggleUpvoteRequest(
          requestId: requestId,
          clientId: user.id.uuidString
        )
      )
      return true
    } catch {
      updateViewerUpvotes(requestId: requestId, isUpvoted: wasUpvoted)
      updateCachedUpvote(requestId: requestId, isUpvoted: wasUpvoted)
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
}
