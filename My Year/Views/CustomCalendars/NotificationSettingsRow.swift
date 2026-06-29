import SwiftUI

struct NotificationSettingsRow: View {
  let summary: String
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Notification settings")
            .labelStyle(type: .secondary)
          Text(summary)
            .font(.caption)
            .foregroundStyle(.textTertiary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(AppFont.mono(12))
          .foregroundStyle(.textTertiary)
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
    .sameLevelBorder(isFlat: true)
  }
}
