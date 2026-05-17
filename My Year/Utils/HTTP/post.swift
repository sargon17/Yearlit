import Foundation

extension HTTP {
    public static func post(endpoint: String, headers: [String: String] = [:], data: Codable) async throws {
        guard let url = URL(string: endpoint) else {
            throw POSTError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let jsonData = try JSONEncoder().encode(data)

        request.httpBody = jsonData

        let (responseData, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse else {
            throw POSTError.invalidResponse
        }

        guard (200 ... 299).contains(response.statusCode) else {
            let body = String(data: responseData, encoding: .utf8)
            throw POSTError.badStatus(response.statusCode, body)
        }
    }

    enum POSTError: LocalizedError {
        case invalidURL
        case invalidResponse
        case badStatus(Int, String?)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid HTTP response"
            case let .badStatus(statusCode, body):
                return "HTTP status \(statusCode): \(body ?? "<empty body>")"
            }
        }
    }
}
