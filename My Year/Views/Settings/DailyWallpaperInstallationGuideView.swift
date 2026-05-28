import AppIntents
import SwiftUI

struct DailyWallpaperInstallationGuideView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      Section(header: Text("Actions")) {
        DailyWallpaperSetupStepRow(
          number: 1,
          title: "Create Daily Wallpaper",
          subtitle: "Yearlit generates the selected wallpaper."
        )
        DailyWallpaperSetupStepRow(
          number: 2,
          title: "Set Wallpaper",
          subtitle: "Use the Daily Wallpaper output. Turn Show Preview off."
        )
      }

      Section(header: Text("Automation")) {
        DailyWallpaperSetupStepRow(number: 1, title: "Time of Day", subtitle: "Set it to 12:00 AM.")
        DailyWallpaperSetupStepRow(
          number: 2,
          title: "Repeat Daily",
          subtitle: "Run the wallpaper refresh every day."
        )
        DailyWallpaperSetupStepRow(
          number: 3,
          title: "Run Immediately",
          subtitle: "Do not ask before running."
        )
      }

      Section {
        ShortcutsLink()
          .shortcutsLinkStyle(.automatic)
      }
    }
    .scrollContentBackground(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Installation Guide")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          dismiss()
        }
      }
    }
  }
}

private struct DailyWallpaperSetupStepRow: View {
  let number: Int
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey

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
