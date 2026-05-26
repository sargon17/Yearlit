import AppIntents
import SwiftUI
import SwiftfulRouting

struct DailyWallpaperSettingsSection: View {
  @Environment(\.router) private var router

  var body: some View {
    Section(header: Text("Daily Wallpaper")) {
      Button {
        router.showScreen(.sheet) { _ in
          NavigationStack {
            DailyWallpaperSetupView()
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

private struct DailyWallpaperSetupView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Text("Shortcut setup")
            .font(AppFont.mono(16, weight: .bold))
            .foregroundColor(Color("text-primary"))

          Text("Two Shortcut actions. No Photos step.")
            .font(AppFont.mono(12))
            .foregroundColor(Color("text-secondary"))
        }
        .padding(.vertical, 4)
      }

      Section(header: Text("Actions")) {
        SetupStepRow(number: 1, title: "Create Daily Wallpaper", subtitle: "Yearlit generates and prepares the image.")
        SetupStepRow(number: 2, title: "Set Wallpaper", subtitle: "Use the Daily Wallpaper output. Turn Show Preview off.")
      }

      Section(header: Text("Automation")) {
        SetupStepRow(number: 1, title: "Time of Day", subtitle: "Set it to 12:00 AM.")
        SetupStepRow(number: 2, title: "Repeat Daily", subtitle: "Run the wallpaper refresh every day.")
        SetupStepRow(number: 3, title: "Run Immediately", subtitle: "Do not ask before running.")
      }

      Section {
        ShortcutsLink()
          .shortcutsLinkStyle(.automatic)
      } footer: {
        Text("iOS does not allow apps to set wallpaper directly. Test this on a physical iPhone; Simulator may apply custom photo wallpapers as black.")
      }
    }
    .scrollContentBackground(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Daily Wallpaper")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          dismiss()
        }
      }
    }
  }
}

private struct SetupStepRow: View {
  let number: Int
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(number.description)
        .font(AppFont.mono(12, weight: .bold))
        .foregroundColor(Color("surface-muted"))
        .frame(width: 24, height: 24)
        .background(Color("qs-orange"))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.mono(13, weight: .bold))
          .foregroundColor(Color("text-primary"))

        Text(subtitle)
          .font(AppFont.mono(11))
          .foregroundColor(Color("text-secondary"))
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    DailyWallpaperSetupView()
  }
}
