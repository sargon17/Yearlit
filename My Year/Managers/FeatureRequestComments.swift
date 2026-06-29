import Foundation

@MainActor
extension FeatureRequestManager {
  func getComments(requestId: String) async -> [FeatureRequestComment] {
    guard let apiContext else {
      logError("Missing configuration for comments")
      return []
    }

    let endpoint = apiContext.projectEndpoint("/request/\(requestId)/comments")

    do {
      let response = try await HTTP.get(
        endpoint: endpoint,
        headers: apiContext.headers,
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
    guard let apiContext else {
      logError("Missing configuration for comment creation")
      return []
    }

    let endpoint = apiContext.projectEndpoint("/request/\(requestId)/comment")

    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: apiContext.headers,
        data: FeatureRequestCreateCommentRequest(
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
    guard let apiContext else {
      logError("Missing configuration for comment deletion")
      return false
    }

    let clientId = user.id.uuidString
    let endpoint = apiContext.projectEndpoint(
      "/request/\(requestId)/comment/\(comment.id)?clientId=\(clientId)"
    )

    do {
      try await HTTP.delete(endpoint: endpoint, headers: apiContext.headers)
      return true
    } catch {
      logError("Failed to delete comment", error: error)
      return false
    }
  }
}
