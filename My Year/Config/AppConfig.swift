import Foundation

enum AppConfig {
    static let revenueCatAPIKey: String = {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("Missing REVENUECAT_API_KEY")
        }

        return key
    }()
}
