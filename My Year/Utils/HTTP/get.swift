import SwiftUI

extension HTTP {
    public static func get<T: Decodable & Decodable>(endpoint: String, type: T.Type) async throws -> T {
        log("GET \(endpoint)")
        guard let url = URL(string: endpoint) else {
            log("GET invalid URL")
            throw GetError.error1
        }

        let (data, res): (Data, URLResponse)
        do {
            (data, res) = try await URLSession.shared.data(from: url)
        } catch {
            log("GET transport error: \(error.localizedDescription)")
            throw error
        }

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            if let response = res as? HTTPURLResponse {
                log("GET failed status=\(response.statusCode) body=\(responseBody)")
            } else {
                log("GET failed invalid response body=\(responseBody)")
            }
            throw GetError.error2
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            log("GET decode error: \(error.localizedDescription) body=\(responseBody)")
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
