import SwiftUI

struct PickerOptionTile<Content: View>: View {
    let isSelected: Bool
    let isEnabled: Bool
    let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .greatestFiniteMagnitude, minHeight: 56)
        .padding(6)
        .opacity(isEnabled ? 1 : 0.7)
        .sameLevelBorder()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PickerOptionContent: View {
    let icon: String
    let title: LocalizedStringKey
    let accentColor: Color
    let isSelected: Bool

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? accentColor : .textSecondary)

            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(isSelected ? accentColor : .textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
