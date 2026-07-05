import Foundation

struct WishConfiguration {
  let baseURL: String
  let projectID: String
  let apiKey: String
}

enum AppConfig {
  static let privacyPolicyURL = URL(string: "https://yearlit.com/privacy-policy/")!
  static let termsURL = URL(string: "https://yearlit.com/terms/")!

  static let postHogConfiguration: PostHogConfiguration = {
    let token = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_PROJECT_TOKEN") as? String
    let host = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_HOST") as? String
    let enabledInDebug = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_ENABLED") as? String == "YES"

    return PostHogConfiguration(
      projectToken: token?.trimmingCharacters(in: .whitespacesAndNewlines),
      host: host?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "https://us.i.posthog.com",
      enabledInDebug: enabledInDebug
    )
  }()

  static let revenueCatAPIKey: String = {
    guard
      let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
      !key.isEmpty
    else {
      fatalError("Missing REVENUECAT_API_KEY")
    }

    return key
  }()

  static let wishConfiguration: WishConfiguration? = {
    guard
      let rawBaseURL = Bundle.main.object(forInfoDictionaryKey: "WISH_BASE_URL") as? String,
      let rawProjectID = Bundle.main.object(forInfoDictionaryKey: "WISH_PROJECT_ID") as? String,
      let rawAPIKey = Bundle.main.object(forInfoDictionaryKey: "WISH_API_KEY") as? String
    else {
      return nil
    }

    let baseURL = rawBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    let projectID = rawProjectID.trimmingCharacters(in: .whitespacesAndNewlines)
    let apiKey = rawAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !baseURL.isEmpty, !projectID.isEmpty, !apiKey.isEmpty else {
      return nil
    }

    let normalizedBaseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    let normalizedProjectID = projectID.replacingOccurrences(of: "projects:", with: "")

    return WishConfiguration(
      baseURL: normalizedBaseURL,
      projectID: normalizedProjectID,
      apiKey: apiKey
    )
  }()
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
