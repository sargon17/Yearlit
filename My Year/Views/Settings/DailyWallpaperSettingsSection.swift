import RevenueCat
import SwiftUI
import SwiftfulRouting

struct DailyWallpaperSettingsSection: View {
  @Environment(\.router) private var router
  let customerInfo: CustomerInfo?

  var body: some View {
    Section(header: Text("Daily Wallpaper")) {
      Button {
        router.showScreen(.sheet) { _ in
          NavigationStack {
            DailyWallpaperSetupView(customerInfo: customerInfo)
          }
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
        }
      } label: {
        Label("Set Up Daily Wallpaper", systemImage: "photo.on.rectangle")
      }
    }
  }
}
