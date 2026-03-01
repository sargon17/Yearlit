import SwiftUI

struct FeatureRequestsListItem: View {
  let request: Request
  let isUpvoted: Bool
  let isTogglingUpvote: Bool
  let onToggleUpvote: () -> Void

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(request.text).h4()
        if featureRequestManager.isCurrentUser(id: request.clientId) {
          Text("your")
            .padding(.horizontal, 4)
            .background(.surfaceMuted)
            .foregroundColor(.textSecondary)
            .cornerRadius(4)
            .font(.system(size: 9))
        }
      }

      FeatureStatusBadge(
        label: request.computedStatus.displayName,
        color: request.computedStatus.color
      )

      if let description = request.description {
        Text(description)
          .body()
          .lineLimit(3)
      }

      HStack(spacing: 12) {
        Button {
          onToggleUpvote()
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
    }
  }
}
