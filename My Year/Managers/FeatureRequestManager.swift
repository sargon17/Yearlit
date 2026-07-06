import Foundation

enum FeatureRequestKind: String, Codable {
  case request
  case complaint
}

/// Thin client for the Wish HTTP API, kept only for programmatic request
/// creation (in-app satisfaction feedback) and the stable per-device client
/// id shared with the hosted Wish embed. All user-facing feedback UI is the
/// embedded `WishView`.
enum FeatureRequestManager {
  private enum Constants {
    static let userDefaultsKey = "FeatureRequestManager.userUUID"
    static let keychainService = "com.tymofyeyev.yearlit.wish"
    static let keychainAccount = "feature-request-client-id"
  }

  private struct CreateRequest: Codable {
    let text: String
    let description: String?
    let clientId: String
    let project: String
    let kind: FeatureRequestKind?
  }

  static var isConfigured: Bool {
    AppConfig.wishConfiguration != nil
  }

  /// Stable per-device client id shared with the hosted Wish embed so
  /// existing request/upvote attribution carries over.
  static func stableClientId() -> String {
    let defaults = UserDefaults.standard

    if let keychainValue = KeychainStore.read(
      account: Constants.keychainAccount,
      service: Constants.keychainService
    ),
      let keychainUUID = UUID(uuidString: keychainValue)
    {
      return keychainUUID.uuidString
    }

    if let storedValue = defaults.string(forKey: Constants.userDefaultsKey),
      let storedUUID = UUID(uuidString: storedValue)
    {
      KeychainStore.save(
        value: storedUUID.uuidString,
        account: Constants.keychainAccount,
        service: Constants.keychainService
      )
      return storedUUID.uuidString
    }

    let newUUID = UUID()
    defaults.set(newUUID.uuidString, forKey: Constants.userDefaultsKey)
    KeychainStore.save(
      value: newUUID.uuidString,
      account: Constants.keychainAccount,
      service: Constants.keychainService
    )
    return newUUID.uuidString
  }

  /// Creates a Wish request. Returns `false` when Wish is unconfigured or
  /// the network call fails.
  static func createRequest(
    text: String,
    description: String?,
    kind: FeatureRequestKind? = nil
  ) async -> Bool {
    guard let config = AppConfig.wishConfiguration else {
      logError("Missing configuration for request creation")
      return false
    }

    let trimmedDescription = description?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let endpoint = "\(config.apiBaseURL)/api/project/\(config.projectID)/request/"
    do {
      try await HTTP.post(
        endpoint: endpoint,
        headers: ["x-api-key": config.apiKey],
        data: CreateRequest(
          text: text.trimmingCharacters(in: .whitespacesAndNewlines),
          description: trimmedDescription?.isEmpty == true ? nil : trimmedDescription,
          clientId: stableClientId(),
          project: config.projectID,
          kind: kind
        )
      )
      return true
    } catch {
      logError("Failed to create request", error: error)
      return false
    }
  }

  private static func logError(_ message: String, error: Error? = nil) {
    #if DEBUG
      if let error {
        print("Wish integration error: \(message) - \(error.localizedDescription)")
      } else {
        print("Wish integration error: \(message)")
      }
    #endif
  }
}
