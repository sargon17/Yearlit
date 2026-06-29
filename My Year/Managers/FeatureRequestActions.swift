import Foundation

@MainActor
extension FeatureRequestManager {
  func deleteRequest(id requestId: String) async {
    guard let currentRequests = requests,
          currentRequests.requests.contains(where: { $0.id == requestId }) else {
      return
    }
    guard let apiContext else {
      logError("Missing configuration for request deletion")
      return
    }

    let clientId = user.id.uuidString
    let endpoint = apiContext.projectEndpoint("/request/\(requestId)?clientId=\(clientId)")

    do {
      try await HTTP.delete(endpoint: endpoint, headers: apiContext.headers)
      var updated = currentRequests
      updated.requests.removeAll { $0.id == requestId }
      requests = updated
      updateViewerUpvotes(requestId: requestId, isUpvoted: false)
    } catch {
      logError("Failed to delete request", error: error)
    }
  }

  func createRequest(
    text: String,
    description: String?,
    kind: FeatureRequestKind? = nil,
    onSuccess: (() -> Void)? = nil,
    onError: (() -> Void)? = nil
  ) async {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedText.count >= FeatureRequestRules.minimumTitleLength else {
      onError?()
      return
    }

    guard let apiContext else {
      logError("Missing configuration for request creation")
      onError?()
      return
    }

    let trimmedDescription = description?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let endpoint = apiContext.projectEndpoint("/request/")
    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: apiContext.headers,
        data: CreateRequest(
          text: trimmedText,
          description: trimmedDescription?.isEmpty == true ? nil : trimmedDescription,
          clientId: user.id.uuidString,
          project: apiContext.projectID,
          kind: kind
        )
      )

      requests = nil
      onSuccess?()
    } catch {
      logError("Failed to create request", error: error)
      onError?()
    }
  }
}
