import SwiftUI

struct FeatureRequestsListItem: View {
  let request: Request

  var body: some View {
    VStack(alignment: .leading) {
      Text(request.text).h4()
      Text(request.computedStatus.displayName).body()
      if let description = request.description {
        Text(description).body()
      }
    }
  }
}
