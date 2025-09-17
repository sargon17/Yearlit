import SwiftUI
import SwiftfulRouting

struct AppRouter: View {

  var body: some View {
    TabView {
      CalendarsSection()
        .tabItem {
          Label("Calendars", systemImage: "calendar")
        }

      StackSection()
        .tabItem({
          Label("Stack", systemImage: "rectangle.stack")
        })
    }
    .ignoresSafeArea(edges: .bottom)
  }
}
