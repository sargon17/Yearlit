import SwiftUI
import SwiftfulRouting

struct FeatureRequestsList: View {
  @State private var requestsList: FeatureRequestsListResponse?
  @State private var showsOnlyMine = false

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager
  @Environment(\.router) private var router

  var body: some View {
    VStack {
      List {
        ForEach(groupedRequests) { group in
          Section(group.status.displayName) {
            ForEach(group.requests) { request in
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
        }
      }
      .animation(.easeInOut, value: groupedRequests)
    }
    .navigationTitle("Feature Requests")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          withAnimation {
            showsOnlyMine.toggle()
          }
        } label: {
          Label("Your Requests", systemImage: showsOnlyMine ? "person.fill" : "person")
        }
        .accessibilityLabel("Filter your requests")
      }
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
  struct RequestGroup: Identifiable, Equatable {
    let status: RequestStatus
    let requests: [Request]

    var id: String { status._id }

    static func == (lhs: RequestGroup, rhs: RequestGroup) -> Bool {
      lhs.status._id == rhs.status._id && lhs.requests.map(\.id) == rhs.requests.map(\.id)
    }
  }

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

  var groupedRequests: [RequestGroup] {
    let requests = (requestsList?.requests ?? [])
      .filter { request in
        !showsOnlyMine || featureRequestManager.isCurrentUser(id: request.clientId)
      }
    let grouped = Dictionary(grouping: requests, by: { $0.computedStatus._id })
    return grouped
      .compactMap { _, requests in
        guard let status = requests.first?.computedStatus else { return nil }
        let sortedRequests = requests.sorted { $0._creationTime > $1._creationTime }
        return RequestGroup(status: status, requests: sortedRequests)
      }
      .sorted { $0.status.displayName.localizedCaseInsensitiveCompare($1.status.displayName) == .orderedAscending }
  }
}
