import Foundation

extension HTTP {
    public static func get<T: Decodable>(
        endpoint: String,
        headers: [String: String] = [:],
        type: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw GetError.invalidURL
        }

        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, res): (Data, URLResponse)
        do {
            (data, res) = try await URLSession.shared.data(for: request)
        } catch {
            throw error
        }

        guard let response = res as? HTTPURLResponse else {
            throw GetError.invalidResponse
        }

        guard (200 ... 299).contains(response.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw GetError.badStatus(response.statusCode, body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8)
            throw GetError.decodingFailed(error, body)
        }
    }

    enum GetError: LocalizedError {
        case invalidURL
        case invalidResponse
        case badStatus(Int, String?)
        case decodingFailed(Error, String?)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid HTTP response"
            case let .badStatus(statusCode, body):
                return "HTTP status \(statusCode): \(body ?? "<empty body>")"
            case let .decodingFailed(error, body):
                return "Decoding failed: \(error.localizedDescription). Body: \(body ?? "<empty body>")"
            }
        }
    }
}
