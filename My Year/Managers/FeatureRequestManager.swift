import Combine
import Foundation
import Observation

@MainActor
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

  private var apiBaseURL: String? {
    config.map { "\($0.baseURL)/api" }
  }

  private var projectID: String? {
    config?.projectID
  }

  private var authHeaders: [String: String] {
    guard let apiKey = config?.apiKey else { return [:] }
    return ["x-api-key": apiKey]
  }

  private func logError(_ message: String, error: Error? = nil) {
    #if DEBUG
      if let error {
        print("Wish integration error: \(message) - \(error.localizedDescription)")
      } else {
        print("Wish integration error: \(message)")
      }
    #endif
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

  func getUserId() -> String {
    user.id.uuidString
  }

  func isCurrentUser(id: String) -> Bool {
    id == user.id.uuidString
  }

  func invalidateRequests() {
    requests = nil
  }

  func getRequests() async -> FeatureRequestsListResponse? {
    if let requests {
      return requests
    }
    return await reloadRequests()
  }

  func reloadRequests() async -> FeatureRequestsListResponse? {
    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for request reload")
      return requests
    }

    let endpoint = "\(apiBaseURL)/project/\(projectID)/requests/"
    do {
      let fetched = try await HTTP.get(
        endpoint: endpoint,
        headers: authHeaders,
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

    guard let apiBaseURL, let projectID else {
      viewerUpvotesLoaded = true
      upvotesSupported = false
      logError("Missing configuration for viewer upvotes")
      return viewerUpvotes
    }

    let clientId = user.id.uuidString
    let endpoint = "\(apiBaseURL)/project/\(projectID)/upvotes?clientId=\(clientId)"

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        headers: authHeaders,
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

  func getComments(requestId: String) async -> [FeatureRequestComment] {
    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for comments")
      return []
    }

    let endpoint = "\(apiBaseURL)/project/\(projectID)/request/\(requestId)/comments"

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        headers: authHeaders,
        type: FeatureRequestCommentsResponse.self
      )
      return response.comments.filter {
        !$0.body.isEmpty && ($0.isDeveloper || !$0.authorClientId.isEmpty)
      }
    } catch {
      logError("Failed to fetch comments", error: error)
      return []
    }
  }

  func addComment(requestId: String, text: String) async -> [FeatureRequestComment] {
    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for comment creation")
      return []
    }

    let endpoint = "\(apiBaseURL)/project/\(projectID)/request/\(requestId)/comment"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: authHeaders,
        data: CreateCommentRequest(
          body: text,
          clientId: user.id.uuidString
        )
      )
    } catch {
      logError("Failed to create comment", error: error)
      return []
    }

    return await getComments(requestId: requestId)
  }

  func deleteComment(requestId: String, comment: FeatureRequestComment) async -> Bool {
    guard isCurrentUser(id: comment.authorClientId) else { return false }
    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for comment deletion")
      return false
    }

    let clientId = user.id.uuidString
    let endpoint = "\(apiBaseURL)/project/\(projectID)/request/\(requestId)/comment/\(comment.id)?clientId=\(clientId)"

    do {
      try await HTTP.delete(endpoint: endpoint, headers: authHeaders)
      return true
    } catch {
      logError("Failed to delete comment", error: error)
      return false
    }
  }

  func toggleUpvote(requestId: String, wasUpvoted: Bool? = nil) async -> Bool {
    guard upvotesSupported else {
      return false
    }
    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for upvote toggle")
      return false
    }

    let currentWasUpvoted = wasUpvoted ?? viewerUpvotes.contains(requestId)
    let nextUpvoted = !currentWasUpvoted
    updateViewerUpvotes(requestId: requestId, isUpvoted: nextUpvoted)
    updateCachedUpvote(requestId: requestId, isUpvoted: nextUpvoted)

    let endpoint = "\(apiBaseURL)/project/\(projectID)/request/\(requestId)/upvote"

    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: authHeaders,
        data: ToggleUpvoteRequest(
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
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedText.count >= FeatureRequestRules.minimumTitleLength else {
      onError?()
      return
    }

    guard let apiBaseURL, let projectID else {
      logError("Missing configuration for request creation")
      onError?()
      return
    }

    let trimmedDescription = description?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let endpoint = "\(apiBaseURL)/project/\(projectID)/request/"
    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: authHeaders,
        data: CreateRequest(
          text: trimmedText,
          description: trimmedDescription?.isEmpty == true ? nil : trimmedDescription,
          clientId: user.id.uuidString,
          project: projectID
        )
      )

      invalidateRequests()
      onSuccess?()
    } catch {
      logError("Failed to create request", error: error)
      onError?()
    }
  }
}
