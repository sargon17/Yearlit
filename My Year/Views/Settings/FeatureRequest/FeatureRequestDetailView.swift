import SwiftUI

struct FeatureRequestDetailView: View {
  @State private var request: Request
  @State private var comments: [FeatureRequestComment] = []
  @State private var commentText = ""
  @State private var isSubmittingComment = false
  @State private var isTogglingUpvote = false

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager

  init(request: Request) {
    _request = State(initialValue: request)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      FeatureStatusBadge(
        label: request.computedStatus.displayName,
        color: request.computedStatus.color
      )
      if let description = request.description {
        Text(description).body()
      }

      HStack(spacing: 12) {
        Button {
          handleUpvote()
        } label: {
          Label("\(request.resolvedUpvoteCount)", systemImage: isUpvoted ? "hand.thumbsup.fill" : "hand.thumbsup")
        }
        .buttonStyle(.borderless)
        .disabled(
          !featureRequestManager.viewerUpvotesLoaded
            || !featureRequestManager.upvotesSupported
            || isTogglingUpvote
        )

        Label("Comments", systemImage: "text.bubble")
          .foregroundColor(.textSecondary)
      }
      .font(.footnote)

      VStack(alignment: .leading, spacing: 12) {
        Text("Comments").h4()
        if comments.isEmpty {
          Text("No comments yet.").body().foregroundColor(.textSecondary)
        } else {
          ForEach(comments) { comment in
            commentRow(comment: comment)
          }
        }
      }

      HStack(alignment: .top, spacing: 8) {
        TextField("Add a comment", text: $commentText)
          .textFieldStyle(.roundedBorder)

        Button("Send") {
          handleAddComment()
        }
        .disabled(isSubmittingComment || commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      Spacer()
    }
    .padding(.horizontal)
    .navigationTitle(request.text)
    .task {
      await refreshComments()
    }
  }
}

extension FeatureRequestDetailView {
  var isUpvoted: Bool {
    featureRequestManager.viewerUpvotes.contains(request.id)
  }

  func refreshComments() async {
    async let comments = featureRequestManager.getComments(requestId: request.id)
    async let _ = featureRequestManager.getViewerUpvotes()
    self.comments = await comments
  }

  func handleAddComment() {
    let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else { return }

    isSubmittingComment = true
    Task {
      let updatedComments = await featureRequestManager.addComment(requestId: request.id, text: trimmedText)
      if !updatedComments.isEmpty {
        comments = updatedComments
        commentText = ""
      }
      isSubmittingComment = false
    }
  }

  func handleDeleteComment(_ comment: FeatureRequestComment) {
    guard featureRequestManager.isCurrentUser(id: comment.authorClientId) else { return }
    let existing = comments
    comments.removeAll { $0.id == comment.id }
    Task {
      let success = await featureRequestManager.deleteComment(requestId: request.id, comment: comment)
      if !success {
        comments = existing
      }
    }
  }

  func handleUpvote() {
    guard !isTogglingUpvote else { return }
    isTogglingUpvote = true

    Task {
      let upvotes = await featureRequestManager.getViewerUpvotes()
      let wasUpvoted = upvotes.contains(request.id)
      updateLocalUpvote(isUpvoted: !wasUpvoted)
      let success = await featureRequestManager.toggleUpvote(requestId: request.id, wasUpvoted: wasUpvoted)
      if !success {
        updateLocalUpvote(isUpvoted: wasUpvoted)
      }
      isTogglingUpvote = false
    }
  }

  func updateLocalUpvote(isUpvoted: Bool) {
    let delta = isUpvoted ? 1 : -1
    let updatedCount = max((request.upvoteCount ?? 0) + delta, 0)
    request = Request(
      _id: request._id,
      _creationTime: request._creationTime,
      text: request.text,
      description: request.description,
      clientId: request.clientId,
      upvoteCount: updatedCount,
      status: request.status,
      project: request.project,
      computedStatus: request.computedStatus
    )
  }

  func commentRow(comment: FeatureRequestComment) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        if comment.isDeveloper {
          Text("developer")
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.surfaceMuted)
            .foregroundColor(.textSecondary)
            .cornerRadius(4)
            .font(.system(size: 10))
        }
        if featureRequestManager.isCurrentUser(id: comment.authorClientId) {
          Text("you")
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.surfaceMuted)
            .foregroundColor(.textSecondary)
            .cornerRadius(4)
            .font(.system(size: 10))
        }
        Spacer()
        if featureRequestManager.isCurrentUser(id: comment.authorClientId) {
          Button(role: .destructive) {
            handleDeleteComment(comment)
          } label: {
            Image(systemName: "trash")
          }
          .buttonStyle(.borderless)
        }
      }
      Text(comment.body).body()
    }
    .padding(.vertical, 8)
  }
}
