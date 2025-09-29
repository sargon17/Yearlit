import SwiftUI
import SwiftfulRouting

struct FeatureRequestForm: View {
  @State private var text = ""
  @State private var description = ""

  @Environment(\.router) private var router
  @EnvironmentObject private var featureRequestManager: FeatureRequestManager

  var body: some View {
    VStack {
      Form {
        TextField("Title", text: $text)
        TextField("Description", text: $description)
      }
    }
    Button {
      Task {
        await handleSubmit()
      }
    } label: {
      Label("send", systemImage: "paperplane")
    }
  }

  func handleSubmit() async {
    do {
      let projectID = featureRequestManager.appID
      let clientID = featureRequestManager.user.id.uuidString

      try await HTTP.post(
        endpoint: "https://qualified-viper-293.convex.site/api/project/\(projectID)/request/",
        data: CreateRequest(
          text: text,
          description: description,
          clientId: clientID,
          project: projectID
        )
      )

      router.dismissScreen()

    } catch {
      print("error posting")
      router.showAlert(title: "Something went wrong, please retry later")
    }
  }
}
