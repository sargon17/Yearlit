import SwiftUI
import SwiftfulRouting

struct FeatureRequestsList: View {
  @State private var requestsList: FeatureRequestsListResponse?

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager
  @Environment(\.router) private var router

  var body: some View {
    VStack {
      List(requestsList?.requests ?? []) { request in
        FeatureRequestsListItem(
          request: request
        )
        .contentShape(Rectangle())
        .onTapGesture {
          router.showScreen(.push) { _ in
            FeatureRequestDetailView(request: request)
          }
        }
      }
    }
    .navigationTitle("Feature Requests")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        createRequestButton
      }
    }
    .task {
    }.refreshable {
      await updateList()
    }
    .onAppear {
      Task {
        requestsList = await featureRequestManager.getRequests()
      }
    }
  }
}

extension FeatureRequestsList {
  var createRequestButton: some View {
    Button {
      router.showScreen(
        .push,
        // onDismiss: {
        //   Task {
        //     await updateList()
        //   }
        // }
      ) { _ in
        FeatureRequestForm()
      }
    } label: {
      Label("New Request", systemImage: "plus")
    }
  }

  func updateList() async {
    print("hello there")
    requestsList = await featureRequestManager.reloadRequests()
  }
}
