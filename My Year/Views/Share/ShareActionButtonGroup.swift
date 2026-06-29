import SwiftUI

struct ShareActionButtonGroup: View {
    let onShare: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 2) {
                actionButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    action: onShare
                )
                actionButton(
                    title: "Save to Photos",
                    systemImage: "square.and.arrow.down",
                    action: onSave
                )
            }
            .padding(2)
            .sameLevelGroupBackground()
        }
    }

    private func actionButton(
        title: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(AppFont.mono(14))
            .foregroundColor(.textPrimary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .sameLevelBorder()
        .foregroundStyle(.textSecondary)
    }
}
