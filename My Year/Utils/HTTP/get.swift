import SwiftUI

extension HTTP {

  public static func get<T: Decodable>(endpoint: String, type: T.Type) async throws -> T where T: Decodable {

    guard let url = URL(string: endpoint) else {
      print("error 1")
      throw GetError.error1
    }

    let (data, res) = try await URLSession.shared.data(from: url)

    guard let response = res as? HTTPURLResponse, response.statusCode == 200 else {
      print("error 2")
      throw GetError.error2
    }

    do {
      let decoder = JSONDecoder()
      return try decoder.decode(type, from: data)
    } catch {
      print("error 3")
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
