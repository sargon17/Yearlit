import RevenueCat

enum RevenueCatClient {
  private(set) static var isConfigured = false

  static func configure(apiKey: String) {
    guard !isConfigured else { return }
    Purchases.configure(withAPIKey: apiKey)
    isConfigured = true
  }
}
