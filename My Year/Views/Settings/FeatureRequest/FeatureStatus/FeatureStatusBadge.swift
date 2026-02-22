import SwiftUI

struct FeatureStatusBadge: View {
    var label: String

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 8, height: 8)
                Text(label).font(.system(size: 9))
                    .foregroundColor(.textSecondary)
            }
            .padding(.leading, 4)
            .padding(.trailing, 6)
            .padding(.vertical, 2)
        }
        .background(.surfaceMuted)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    .black.opacity(0.1)
                )
        )
        .cornerRadius(8)
    }
}
