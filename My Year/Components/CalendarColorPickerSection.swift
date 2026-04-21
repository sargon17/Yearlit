import SwiftUI

struct CalendarColorPickerSection: View {
    struct Option: Identifiable {
        let assetName: String
        let accessibilityName: LocalizedStringKey

        var id: String { assetName }
    }

    static let options = [
        Option(assetName: "mood-terrible", accessibilityName: "Red"),
        Option(assetName: "mood-bad", accessibilityName: "Orange"),
        Option(assetName: "qs-amber", accessibilityName: "Amber"),
        Option(assetName: "mood-neutral", accessibilityName: "Yellow"),
        Option(assetName: "qs-lime", accessibilityName: "Lime"),
        Option(assetName: "mood-good", accessibilityName: "Green"),
        Option(assetName: "qs-emerald", accessibilityName: "Emerald"),
        Option(assetName: "qs-teal", accessibilityName: "Teal"),
        Option(assetName: "qs-cyan", accessibilityName: "Cyan"),
        Option(assetName: "qs-sky", accessibilityName: "Sky Blue"),
        Option(assetName: "qs-blue", accessibilityName: "Blue"),
        Option(assetName: "qs-indigo", accessibilityName: "Indigo"),
        Option(assetName: "mood-excellent", accessibilityName: "Purple"),
        Option(assetName: "qs-fuchsia", accessibilityName: "Fuchsia"),
        Option(assetName: "qs-pink", accessibilityName: "Pink"),
        Option(assetName: "qs-rose", accessibilityName: "Rose"),
    ]

    @Binding var selectedColor: String

    var body: some View {
        CustomSection(label: "Color") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Self.options) { option in
                        Button {
                            withAnimation(.snappy) {
                                selectedColor = option.assetName
                            }
                            Task {
                                await hapticFeedback(.rigid)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(option.assetName))
                                    .frame(width: 30, height: 30)

                                Circle()
                                    .stroke(.white, lineWidth: selectedColor == option.assetName ? 2 : 0)
                                    .frame(width: 30, height: 30)
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.accessibilityName)
                        .accessibilityHint(Text("Select calendar color"))
                        .accessibilityAddTraits(selectedColor == option.assetName ? .isSelected : [])
                    }
                }
                .padding(2)
                .padding(.horizontal, 10)
            }
            .padding(.vertical)
            .scrollClipDisabled(true)
            .sameLevelBorder(radius: 6, color: .black)
            .patternStyle()
            .cornerRadius(6)
        }
    }

}
