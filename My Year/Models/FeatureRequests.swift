import Foundation

struct WishAppUser: Codable, Equatable {
  let id: UUID

  init(id: UUID = UUID()) {
    self.id = id
  }
}

struct FeatureRequestsListResponse: Codable {
  let project: Project
  let requests: [Request]
}

struct Project: Codable {
  let _creationTime: Double
  let _id: String
  let title: String
  let user: String
}

struct CreateRequest: Codable {
  let text: String
  let description: String?
  let clientId: String
  let project: String  // riferimento a un id di projects
}

struct Request: Codable, Identifiable {
  let _id: String
  let _creationTime: Double
  let text: String
  let description: String?
  let clientId: String
  let status: String  // riferimento a un id di requestStatuses
  let project: String  // riferimento a un id di projects
  let computedStatus: RequestStatus

  // SwiftUI identity
  var id: String { _id }
}

struct RequestStatus: Codable, Identifiable {
  let _id: String
  let _creationTime: Double
  let name: String
  let displayName: String
  let description: String?
  let project: String?  // opzionale
  let type: RequestStatusType

  var id: String { _id }
}

enum RequestStatusType: String, Codable {
  case custom
  case `default`
}
