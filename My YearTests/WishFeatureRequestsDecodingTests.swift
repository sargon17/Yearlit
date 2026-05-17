@testable import My_Year
import Foundation
import Testing

struct WishFeatureRequestsDecodingTests {
    @Test func decodesRequestsWhenWishOmitsComputedStatus() throws {
        let json = """
        {
          "project": {
            "_creationTime": 1759073933604.1072,
            "_id": "project-id",
            "title": "Yearlit",
            "user": "user-id"
          },
          "requests": [
            {
              "_creationTime": 1768088132941.5935,
              "_id": "request-id",
              "clientId": "client-id",
              "description": "A feature request",
              "project": "project-id",
              "status": "status-id",
              "text": "Weekly Target",
              "upvoteCount": 1
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(
            FeatureRequestsListResponse.self,
            from: #require(json.data(using: .utf8))
        )

        let request = try #require(response.requests.first)
        #expect(request.id == "request-id")
        #expect(request.status == "status-id")
        #expect(request.computedStatus.id == "wish-fallback-status")
        #expect(request.computedStatus.displayName == "Requests")
    }
}
