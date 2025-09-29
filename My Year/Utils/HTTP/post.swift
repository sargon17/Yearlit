import SwiftUI

extension HTTP {
  public static func post(endpoint: String, data: Codable) async throws {
    print("hello there is post function")
    guard let url = URL(string: endpoint) else {
      print("error 1")
      throw POSTError.error1
    }

    var request = URLRequest(url: url)

    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let jsonData = try JSONEncoder().encode(data)

    print(jsonData)

    request.httpBody = jsonData

    let (data, res) = try await URLSession.shared.data(for: request)

    guard let response = res as? HTTPURLResponse, response.statusCode == 200 else {
      print("error 2")
      throw POSTError.error2
    }

    // do {
    //   let decoder = JSONDecoder()
    //   return try decoder.decode(type, from: data)
    // } catch {
    //   print("error 3")
    //   throw GetError.error3
    // }
  }

  enum POSTError: Error {
    case error1
    case error2
    case error3
    case error4
  }
}
