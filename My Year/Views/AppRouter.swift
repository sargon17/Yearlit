import SwiftUI
import SwiftfulRouting

struct AppRouter: View {
  @State private var selectedIndex: Int = 1

  var body: some View {
    TabView(selection: $selectedIndex) {
      CalendarsSection()
        .tabItem {
          Label("Calendars", systemImage: "calendar")
        }
        .tag(0)

      StackSection()
        .tabItem {
          Label("Stack", systemImage: "rectangle.stack")
        }
        .tag(1)
    }
    .ignoresSafeArea(edges: .bottom)
  }
}
