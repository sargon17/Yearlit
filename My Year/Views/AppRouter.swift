import SwiftUI
import SwiftfulRouting

struct AppRouter: View {
  /*
  @State private var selectedIndex: Int = 0

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
  */

  var body: some View {
    CalendarsSection()
      .ignoresSafeArea(edges: .bottom)
  }
}
