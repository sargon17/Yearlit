import SwiftUI

struct CalendarDangerZoneSection: View {
  let isArchived: Bool
  @Binding var showingDeleteConfirmation: Bool
  let onArchiveToggle: () -> Void
  let onDelete: () -> Void

  var body: some View {
    CustomSection(label: "Danger Zone") {
      VStack(spacing: 2) {
        Button(action: onArchiveToggle) {
          Text(String(localized: isArchived ? "Unarchive Calendar" : "Archive Calendar"))
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
            .padding()
        }
        .sameLevelBorder()
        .foregroundStyle(.textSecondary)
      }
      .padding(.all, 2)

      Text(archiveDescription)
        .font(.footnote)
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)

      VStack(spacing: 2) {
        Button(
          action: { showingDeleteConfirmation = true },
          label: {
            Text("Delete Calendar")
              .frame(maxWidth: .infinity, alignment: .center)
              .fontWeight(.bold)
              .padding()
          }
        )
        .sameLevelBorder(color: .moodTerrible)
        .foregroundStyle(.surfaceMuted)
      }
      .padding(.all, 2)
    }
    .alert("Delete Calendar", isPresented: $showingDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive, action: onDelete)
    } message: {
      Text("Are you sure you want to delete this calendar? This action cannot be undone.")
    }
  }

  private var archiveDescription: LocalizedStringKey {
    isArchived
      ? "Unarchiving restores this calendar to your boards and tracking lists."
      : "Archiving hides this calendar from your boards without deleting past data."
  }
}
