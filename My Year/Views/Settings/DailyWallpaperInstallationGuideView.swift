import AppIntents
import SwiftUI

struct DailyWallpaperInstallationGuideView: View {
  @Environment(\.dismiss) private var dismiss
  let accentColor: Color

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        CustomSection(label: "Actions") {
          VStack(alignment: .leading, spacing: 18) {
            DailyWallpaperSetupStepRow(
              number: 1,
              title: "Create Daily Wallpaper",
              subtitle: "Add this first. It creates an image from your saved Yearlit wallpaper settings.",
              accentColor: accentColor
            )
            DailyWallpaperSetupStepRow(
              number: 2,
              title: "Set Wallpaper",
              subtitle: "Add this second. Use the image from Create Daily Wallpaper. Turn Show Preview off.",
              accentColor: accentColor
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        CustomSection(label: "Automation") {
          VStack(alignment: .leading, spacing: 18) {
            DailyWallpaperSetupStepRow(
              number: 1,
              title: "Time of Day",
              subtitle: "Choose when iOS should run the Shortcut.",
              accentColor: accentColor
            )
            DailyWallpaperSetupStepRow(
              number: 2,
              title: "Repeat Daily",
              subtitle: "Run it every day.",
              accentColor: accentColor
            )
            DailyWallpaperSetupStepRow(
              number: 3,
              title: "Run Immediately",
              subtitle: "Turn off Ask Before Running if you want it to apply without confirmation.",
              accentColor: accentColor
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        CustomSection(label: "Shortcuts") {
          VStack(alignment: .leading, spacing: 12) {
            Text("Open Shortcuts, create a personal automation, then add the actions above in order.")
              .font(.footnote)
              .foregroundStyle(.textTertiary)

            Text("The wallpaper changes only when the Shortcut runs, on schedule or manually.")
              .font(.footnote)
              .foregroundStyle(.textTertiary)

            ShortcutsLink()
              .shortcutsLinkStyle(.automaticOutline)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .tint(accentColor)
    .navigationTitle("Installation Guide")
    .toolbarTitleDisplayMode(.inline)
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
  let accentColor: Color

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(number.description)
        .font(AppFont.mono(10, weight: .bold))
        .foregroundColor(accentColor)
        .frame(width: 18, height: 18)
        .background(accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.mono(12, weight: .bold))
          .foregroundColor(Color("text-primary"))

        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(.textTertiary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  NavigationStack {
    DailyWallpaperInstallationGuideView(accentColor: Color("qs-orange"))
  }
}
