import SwiftUI
import SwiftfulRouting

struct FeatureRequestsList: View {
  @State private var response: FeatureRequestsListResponse?

  @Environment(\.router) private var router

  var body: some View {
    VStack {
      List(response?.requests ?? []) { request in
        FeatureRequestsListItem(request: request)
      }
    }
    .navigationTitle("Feature Requests")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          router.showScreen(.push) { _ in
            FeatureRequestForm()
          }
        } label: {
          Label("New Request", systemImage: "plus")
        }
      }
    }
    .task {
      await fetchRequests()
    }.refreshable {
      await fetchRequests()
    }
  }

  func fetchRequests() async {
    let endpoint =
      "https://qualified-viper-293.convex.site/api/project/jd76a32gr7hqyp30trwnds7c5x7rfdxq/requests/"

    do {
      response = try await HTTP.get(
        endpoint: endpoint,
        type: FeatureRequestsListResponse
          .self
      )
    } catch {
      print("error")
    }
  }
}
