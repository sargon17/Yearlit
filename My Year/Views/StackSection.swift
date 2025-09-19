import SharedModels
import SwiftUI
import SwiftfulRouting

struct StackSection: View {
  @StateObject private var store = HabitStackStore.shared

  var body: some View {
    RouterView { _ in
      HabitStacksHome(store: store)
        .page()
    }
  }
}
