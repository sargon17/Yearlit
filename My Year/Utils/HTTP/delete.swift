import SwiftUI

extension HTTP {
    static func delete(endpoint: String, headers: [String: String] = [:]) async throws {
        guard let url = URL(string: endpoint) else {
            throw GetError.error1
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            throw GetError.error2
        }
    }
}
