import Foundation

struct WishAppUser: Codable, Equatable {
  let id: UUID

  init(id: UUID = UUID()) {
    self.id = id
  }
}

struct FeatureRequestsListResponse: Codable {
  let project: Project
  var requests: [Request]
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
  let upvoteCount: Int?
  let status: String  // riferimento a un id di requestStatuses
  let project: String  // riferimento a un id di projects
  let computedStatus: RequestStatus

  // SwiftUI identity
  var id: String { _id }
  var resolvedUpvoteCount: Int { max(upvoteCount ?? 0, 0) }
}

struct FeatureRequestComment: Decodable, Identifiable, Equatable {
  let _id: String
  let _creationTime: Double
  let body: String
  let authorClientId: String
  let isDeveloper: Bool

  var id: String { _id }

  enum CodingKeys: String, CodingKey {
    case _id
    case _creationTime
    case body
    case authorClientId
    case authorType
    case isDeveloper
    case developer
    case isStaff
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    _id = try container.decode(String.self, forKey: ._id)
    _creationTime = (try? container.decode(Double.self, forKey: ._creationTime)) ?? 0
    body = (try? container.decode(String.self, forKey: .body)) ?? ""
    authorClientId = (try? container.decode(String.self, forKey: .authorClientId)) ?? ""
    let isDeveloper = (try? container.decode(Bool.self, forKey: .isDeveloper))
      ?? (try? container.decode(Bool.self, forKey: .developer))
      ?? (try? container.decode(Bool.self, forKey: .isStaff))
      ?? false
    let authorType = (try? container.decode(String.self, forKey: .authorType))?.lowercased()
    self.isDeveloper = isDeveloper || authorType == "developer" || authorType == "staff"
  }
}

struct FeatureRequestCommentsResponse: Decodable {
  let comments: [FeatureRequestComment]

  init(from decoder: Decoder) throws {
    if let container = try? decoder.container(keyedBy: CodingKeys.self),
      let comments = try? container.decode([FeatureRequestComment].self, forKey: .comments)
    {
      self.comments = comments
      return
    }

    let singleValue = try decoder.singleValueContainer()
    comments = (try? singleValue.decode([FeatureRequestComment].self)) ?? []
  }

  enum CodingKeys: String, CodingKey {
    case comments
  }
}

struct FeatureRequestViewerUpvotesResponse: Decodable {
  let upvotes: [String]

  init(from decoder: Decoder) throws {
    if let container = try? decoder.container(keyedBy: CodingKeys.self),
      let upvotes = (try? container.decode([String].self, forKey: .upvotes))
        ?? (try? container.decode([String].self, forKey: .requestIds))
    {
      self.upvotes = upvotes
      return
    }

    let singleValue = try decoder.singleValueContainer()
    upvotes = (try? singleValue.decode([String].self)) ?? []
  }

  enum CodingKeys: String, CodingKey {
    case upvotes
    case requestIds
  }
}

struct RequestStatus: Codable, Identifiable {
  let _id: String
  let _creationTime: Double
  let name: String
  let displayName: String
  let description: String?
  let project: String?  // opzionale
  let type: RequestStatusType
  let color: String?

  var id: String { _id }
}

enum RequestStatusType: String, Codable {
  case custom
  case `default`
}
