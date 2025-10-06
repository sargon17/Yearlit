import SwiftUI

extension HTTP {
  public static func delete(endpoint: String) async throws {
    guard let url = URL(string: endpoint) else {
      print("HTTP.delete: Error parsing the URL")
      throw GetError.error1
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"

    let (_, res) = try await URLSession.shared.data(for: request)

    guard let response = res as? HTTPURLResponse, response.statusCode == 200 else {
      print("HTTP.delete: Error during request")
      throw GetError.error2
    }
  }

  
}
