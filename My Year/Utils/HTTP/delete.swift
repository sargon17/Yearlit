import Foundation

extension HTTP {
    static func delete(endpoint: String, headers: [String: String] = [:]) async throws {
        guard let url = URL(string: endpoint) else {
            throw HTTP.GetError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse else {
            throw HTTP.GetError.invalidResponse
        }

        guard (200 ... 299).contains(response.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw HTTP.GetError.badStatus(response.statusCode, body)
        }
    }
}
