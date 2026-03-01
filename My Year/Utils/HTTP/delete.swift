import SwiftUI

extension HTTP {
    static func delete(endpoint: String) async throws {
        log("DELETE \(endpoint)")
        guard let url = URL(string: endpoint) else {
            log("DELETE invalid URL")
            throw GetError.error1
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            if let response = res as? HTTPURLResponse {
                log("DELETE failed status=\(response.statusCode) body=\(responseBody)")
            } else {
                log("DELETE failed invalid response body=\(responseBody)")
            }
            throw GetError.error2
        }
    }
}
