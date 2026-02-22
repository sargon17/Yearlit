import SwiftUI

struct FeatureRequestDetailView: View {
    let request: Request

    @EnvironmentObject private var featureRequestManager: FeatureRequestManager
    @Environment(\.router) private var router

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FeatureStatusBadge(label: request.computedStatus.displayName)
                // Text(request.computedStatus.displayName).body()
                if let description = request.description {
                    Text(description).body()
                }

                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle(request.text)
        .toolbar {
            if featureRequestManager.isCurrentUser(id: request.clientId) {
                ToolbarItem(placement: .destructiveAction) {
                    deleteButton
                }
            }
        }
    }
}

extension FeatureRequestDetailView {
    var deleteButton: some View {
        Button(role: .destructive) {
            handleDelete()
        } label: {
            Label("delete", systemImage: "trash")
        }.buttonStyle(.borderless)
    }

    func handleDelete() {
        Task {
            await featureRequestManager.deleteRequest(id: request._id)
            router.dismissScreen()
        }
    }
}
