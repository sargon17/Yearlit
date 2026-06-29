import Foundation

struct FeatureRequestAPIContext {
  let baseURL: String
  let projectID: String
  let headers: [String: String]

  func projectEndpoint(_ path: String) -> String {
    "\(baseURL)/project/\(projectID)\(path)"
  }
}

struct FeatureRequestCreateCommentRequest: Codable {
  let body: String
  let clientId: String
}

struct FeatureRequestToggleUpvoteRequest: Codable {
  let clientId: String
}
