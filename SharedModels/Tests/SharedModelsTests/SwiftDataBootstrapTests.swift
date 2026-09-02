import Foundation
import SwiftData
import Testing

@testable import SharedModels

@Suite("SwiftData bootstrap")
struct SwiftDataBootstrapTests {
  @Test("A container creation failure is reported without substituting another store")
  func reportsContainerCreationFailure() {
    struct ExpectedFailure: Error {}
    let expectedURL = URL(fileURLWithPath: "/existing-user-data/SwiftDataStore.store")
    var receivedURL: URL?

    let result = SwiftDataManager.bootstrap(storeURL: expectedURL) { storeURL in
      receivedURL = storeURL
      throw ExpectedFailure()
    }

    #expect(receivedURL == expectedURL)
    guard case .unavailable = result else {
      Issue.record("Expected the existing store failure to be surfaced")
      return
    }
  }
}
