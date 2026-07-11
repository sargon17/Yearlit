import SwiftUI

struct PersistenceUnavailableView: View {
  let details: String

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Image(systemName: "externaldrive.badge.exclamationmark")
        .font(.system(size: 40))
        .foregroundStyle(.orange)

      Text("Your data could not be opened")
        .font(.title.bold())

      Text("Yearlit stopped before making any changes. Your existing data has not been replaced or deleted.")

      Text(
        "Close and reopen the app. If this screen returns, keep the app installed and contact support before trying to restore or reset anything."
      )
      .foregroundStyle(.secondary)

      Text(details)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
    .frame(maxWidth: 520, maxHeight: .infinity, alignment: .center)
    .padding(32)
  }
}
