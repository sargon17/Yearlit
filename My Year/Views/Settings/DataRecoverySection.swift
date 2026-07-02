import SharedModels
import SwiftUI

struct DataRecoveryView: View {
  @State private var backups: [DataBackupMetadata] = []
  @State private var pendingRestore: DataBackupMetadata?
  @State private var errorMessage: String?
  @State private var isRestoring = false

  private let service = DataBackupService.shared

  var body: some View {
    List {
      Section {
        if backups.isEmpty {
          Text("No backups available yet.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(backups) { backup in
            Button {
              pendingRestore = backup
            } label: {
              BackupRow(backup: backup)
            }
            .disabled(isRestoring)
          }
        }
      } header: {
        Text("Backups")
      } footer: {
        Text("Restoring replaces current Calendars, Check-ins, Mood Tracking, journal notes, and Habit Stacks.")
      }
    }
    .navigationTitle("Data & Recovery")
    .onAppear(perform: refresh)
    .confirmationDialog(
      "Restore this backup?",
      isPresented: Binding(
        get: { pendingRestore != nil },
        set: { isPresented in
          if !isPresented {
            pendingRestore = nil
          }
        }
      ),
      titleVisibility: .visible
    ) {
      Button("Restore Backup", role: .destructive) {
        guard let pendingRestore else { return }
        restore(pendingRestore)
      }
      Button("Cancel", role: .cancel) {
        pendingRestore = nil
      }
    } message: {
      Text("Yearlit creates a backup of current data first, then replaces current data with the selected backup.")
    }
    .alert("Restore failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
  }

  private func refresh() {
    backups = service.availableBackups()
  }

  private func restore(_ backup: DataBackupMetadata) {
    isRestoring = true
    pendingRestore = nil
    Task.detached(priority: .userInitiated) {
      do {
        try service.restoreBackup(id: backup.id)
        await MainActor.run {
          CustomCalendarStore.shared.loadCalendars(showLoadingIndicator: false)
          ValuationStore.shared.loadValuations()
          HabitStackStore.shared.loadStacks(showLoadingIndicator: false)
          refresh()
          isRestoring = false
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isRestoring = false
        }
      }
    }
  }
}

private struct BackupRow: View {
  let backup: DataBackupMetadata

  private var createdAt: String {
    backup.createdAt.formatted(date: .abbreviated, time: .shortened)
  }

  private var counts: String {
    "\(backup.counts.calendars) calendars, \(backup.counts.checkIns) check-ins, \(backup.counts.moodEntries) moods, \(backup.counts.journalNotes) notes, \(backup.counts.habitStacks) stacks"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(createdAt)
          .foregroundStyle(.primary)
        Spacer()
        Text(backup.reason.title)
          .foregroundStyle(.secondary)
      }
      .font(AppFont.mono(12, weight: .bold))

      Text(counts)
        .font(AppFont.mono(11))
        .foregroundStyle(.secondary)

      Text("Version \(backup.appVersion) (\(backup.buildNumber))")
        .font(AppFont.mono(11))
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}
