import SwiftUI

extension HTTP {

  public static func get<T: Decodable>(endpoint: String, type: T.Type) async throws -> T where T: Decodable {

    guard let url = URL(string: endpoint) else {
      print("HTTP.get: Error parsing the URL")
      throw GetError.error1
    }

    let (data, res) = try await URLSession.shared.data(from: url)

    guard let response = res as? HTTPURLResponse, response.statusCode == 200 else {
      print("HTTP.get: Error during request")
      throw GetError.error2
    }

    do {
      let decoder = JSONDecoder()
      return try decoder.decode(type, from: data)
    } catch {
      print("HTTP.get: Error decoding the response")
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
