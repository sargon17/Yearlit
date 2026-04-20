import SwiftfulRouting
import SwiftUI

struct FeatureRequestForm: View {
    enum Field: Hashable {
        case text
        case description
    }

    @State private var text = ""
    @State private var description = ""

    @Environment(\.router) private var router
    @EnvironmentObject private var featureRequestManager: FeatureRequestManager

    @FocusState private var focus: Field?

    var body: some View {
        VStack {
            Form {
                TextField("Title", text: $text)
                    .focused($focus, equals: Field.text)
                TextField("Some more context", text: $description, axis: .vertical)
                    .focused($focus, equals: Field.description)
                    .lineLimit(6 ... 12)
            }
        }.onAppear {
            focus = Field.text
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await handleSubmit()
                    }
                } label: {
                    Label("Send request", systemImage: "paperplane")
                }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).count < FeatureRequestRules.minimumTitleLength)
            }
        }.navigationTitle("New Request")
    }

    func handleSubmit() async {
        await featureRequestManager.createRequest(
            text: text,
            description: description,
            onSuccess: {
                router.dismissScreen()
            },
            onError: {
                router.showAlert(
                    .alert,
                    title: "Something went wrong",
                    subtitle: "please try later"
                )
            }
        )
    }
}
