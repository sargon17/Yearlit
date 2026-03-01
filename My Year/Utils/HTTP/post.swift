import SwiftUI

extension HTTP {
    public static func post(endpoint: String, data: Codable) async throws {
        guard let url = URL(string: endpoint) else {
            throw POSTError.error1
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONEncoder().encode(data)

        request.httpBody = jsonData

        let (data, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            throw POSTError.error2
        }
    }

    enum POSTError: Error {
        case error1
        case error2
        case error3
        case error4
    }
}
