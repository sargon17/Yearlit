import SwiftUI

extension HTTP {
    public static func post(endpoint: String, data: Codable) async throws {
        log("POST \(endpoint)")
        guard let url = URL(string: endpoint) else {
            log("POST invalid URL")
            throw POSTError.error1
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONEncoder().encode(data)

        if let payload = String(data: jsonData, encoding: .utf8) {
            log("POST payload=\(payload)")
        } else {
            log("POST payload=<\(jsonData.count) bytes>")
        }

        request.httpBody = jsonData

        let (data, res) = try await URLSession.shared.data(for: request)

        guard let response = res as? HTTPURLResponse,
              (200 ... 299).contains(response.statusCode) else
        {
            let responseBody = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            if let response = res as? HTTPURLResponse {
                log("POST failed status=\(response.statusCode) body=\(responseBody)")
            } else {
                log("POST failed invalid response body=\(responseBody)")
            }
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
