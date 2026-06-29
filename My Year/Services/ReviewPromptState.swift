import Foundation

struct ReviewRules: Codable, Equatable {
  var minEvents: Int = 3
  var cooldownDays: Int = 30
  var oncePerVersion: Bool = true
}

struct ReviewState: Codable {
  var totalEventCount: Int = 0
  var satisfactionPromptCount: Int = 0
  var lastSatisfactionPromptDate: Date?
  var lastReviewRequestDate: Date?
  var lastPromptedVersion: String?

  enum CodingKeys: String, CodingKey {
    case totalEventCount
    case satisfactionPromptCount
    case lastSatisfactionPromptDate
    case lastReviewRequestDate
    case lastPromptedVersion
    case lastPromptDate
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    totalEventCount = try container.decodeIfPresent(Int.self, forKey: .totalEventCount) ?? 0
    satisfactionPromptCount = try container.decodeIfPresent(Int.self, forKey: .satisfactionPromptCount) ?? 0
    lastSatisfactionPromptDate =
      try container.decodeIfPresent(Date.self, forKey: .lastSatisfactionPromptDate)
      ?? container.decodeIfPresent(Date.self, forKey: .lastPromptDate)
    lastReviewRequestDate = try container.decodeIfPresent(Date.self, forKey: .lastReviewRequestDate)
    lastPromptedVersion = try container.decodeIfPresent(String.self, forKey: .lastPromptedVersion)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(totalEventCount, forKey: .totalEventCount)
    try container.encode(satisfactionPromptCount, forKey: .satisfactionPromptCount)
    try container.encodeIfPresent(lastSatisfactionPromptDate, forKey: .lastSatisfactionPromptDate)
    try container.encodeIfPresent(lastReviewRequestDate, forKey: .lastReviewRequestDate)
    try container.encodeIfPresent(lastPromptedVersion, forKey: .lastPromptedVersion)
  }
}
