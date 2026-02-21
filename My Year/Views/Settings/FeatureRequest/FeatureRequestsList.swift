import SwiftUI
import SwiftfulRouting

struct FeatureRequestsList: View {
  @State private var requestsList: FeatureRequestsListResponse?
  @State private var showsOnlyMine = false
  @State private var togglingUpvotes: Set<String> = []

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager
  @Environment(\.router) private var router

  var body: some View {
    VStack {
      List {
        ForEach(groupedRequests) { group in
          Section(group.status.displayName) {
            ForEach(group.requests) { request in
              FeatureRequestsListItem(
                request: request,
                isUpvoted: featureRequestManager.viewerUpvotes.contains(request.id),
                isTogglingUpvote: togglingUpvotes.contains(request.id),
                onToggleUpvote: {
                  handleUpvote(request: request)
                }
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
      await updateList()
    }
    .refreshable {
      await updateList()
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
    async let requests = featureRequestManager.reloadRequests()
    async let upvotes = featureRequestManager.getViewerUpvotes()
    requestsList = await requests
    _ = await upvotes
  }

  func handleUpvote(request: Request) {
    guard !togglingUpvotes.contains(request.id) else { return }
    togglingUpvotes.insert(request.id)

    Task {
      let upvotes = await featureRequestManager.getViewerUpvotes()
      let wasUpvoted = upvotes.contains(request.id)
      updateLocalUpvote(requestId: request.id, isUpvoted: !wasUpvoted)
      let success = await featureRequestManager.toggleUpvote(requestId: request.id, wasUpvoted: wasUpvoted)
      if !success {
        updateLocalUpvote(requestId: request.id, isUpvoted: wasUpvoted)
      }
      togglingUpvotes.remove(request.id)
    }
  }

  func updateLocalUpvote(requestId: String, isUpvoted: Bool) {
    guard var list = requestsList else { return }
    guard let index = list.requests.firstIndex(where: { $0.id == requestId }) else { return }
    let current = list.requests[index]
    let delta = isUpvoted ? 1 : -1
    let updatedCount = max((current.upvoteCount ?? 0) + delta, 0)
    let updatedRequest = Request(
      _id: current._id,
      _creationTime: current._creationTime,
      text: current.text,
      description: current.description,
      clientId: current.clientId,
      upvoteCount: updatedCount,
      status: current.status,
      project: current.project,
      computedStatus: current.computedStatus
    )
    list.requests[index] = updatedRequest
    requestsList = list
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
      .sorted { $0.status._creationTime < $1.status._creationTime }
  }
}
