import SwiftUI

extension HTTP {
    public static func get<T: Decodable & Decodable>(endpoint: String, type: T.Type) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw GetError.error1
        }

        let (data, res): (Data, URLResponse)
        do {
            (data, res) = try await URLSession.shared.data(from: url)
        } catch {
            throw error
        }

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode)
        else {
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
