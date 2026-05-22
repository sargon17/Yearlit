import SwiftUI
import SwiftfulRouting

struct WidgetsSettingsSection: View {
  @Environment(\.router) private var router

  var body: some View {
    Section(header: Text("Widgets")) {
      Button {
        router.showScreen(.sheet) { _ in
          NavigationStack {
            WidgetsShowcaseView()
          }
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
        }
      } label: {
        Label("Preview Widgets", systemImage: "square.grid.2x2")
      }
    }
  }
}
