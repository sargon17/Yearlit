import SwiftUI

extension HTTP {
    public static func get<T: Decodable>(
        endpoint: String,
        headers: [String: String] = [:],
        type: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw GetError.error1
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

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            throw GetError.error2
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw GetError.error3
        }
    }

    enum GetError: Error {
        case error1
        case error2
        case error3
        case error4
    }
}
