import SwiftUI

struct FeatureRequestsListItem: View {
  let request: Request

  @EnvironmentObject private var featureRequestManager: FeatureRequestManager

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(request.text).h4()
        if featureRequestManager.isCurrentUser(id: request.clientId) {
          HStack {
            Text("your")
              .padding(.horizontal, 4)
          }.background(.surfaceMuted)
            .foregroundColor(.textSecondary)
            .cornerRadius(4)
            .font(.system(size: 9))

        }
      }
      Text(request.computedStatus.displayName).body()
      if let description = request.description {
        Text(description).body()
      }
    }
  }
}
