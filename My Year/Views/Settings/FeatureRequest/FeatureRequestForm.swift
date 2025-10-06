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
    await featureRequestManager.createRequest(
      text: text,
      description: description,
      onSuccess: { router.dismissScreen() },
      onError: {
        router.showAlert(title: "Something went wrong, please retry later")
      }
    )
  }
}
