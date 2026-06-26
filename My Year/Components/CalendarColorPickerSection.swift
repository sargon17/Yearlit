import SwiftUI

struct CalendarColorPickerSection: View {
  @Binding var selectedColor: String

  var body: some View {
    CustomSection(label: "Color") {
      ColorSwatchPicker(selectedColor: $selectedColor, accessibilityHint: "Select calendar color")
    }
  }
}

struct ColorSwatchOption: Identifiable {
  let assetName: String
  let accessibilityName: LocalizedStringKey

  var id: String { assetName }
}

struct ColorSwatchPicker: View {
  static let defaultOptions = [
    ColorSwatchOption(assetName: "mood-terrible", accessibilityName: "Red"),
    ColorSwatchOption(assetName: "mood-bad", accessibilityName: "Orange"),
    ColorSwatchOption(assetName: "qs-amber", accessibilityName: "Amber"),
    ColorSwatchOption(assetName: "mood-neutral", accessibilityName: "Yellow"),
    ColorSwatchOption(assetName: "qs-lime", accessibilityName: "Lime"),
    ColorSwatchOption(assetName: "mood-good", accessibilityName: "Green"),
    ColorSwatchOption(assetName: "qs-emerald", accessibilityName: "Emerald"),
    ColorSwatchOption(assetName: "qs-teal", accessibilityName: "Teal"),
    ColorSwatchOption(assetName: "qs-cyan", accessibilityName: "Cyan"),
    ColorSwatchOption(assetName: "qs-sky", accessibilityName: "Sky Blue"),
    ColorSwatchOption(assetName: "qs-blue", accessibilityName: "Blue"),
    ColorSwatchOption(assetName: "qs-indigo", accessibilityName: "Indigo"),
    ColorSwatchOption(assetName: "mood-excellent", accessibilityName: "Purple"),
    ColorSwatchOption(assetName: "qs-fuchsia", accessibilityName: "Fuchsia"),
    ColorSwatchOption(assetName: "qs-pink", accessibilityName: "Pink"),
    ColorSwatchOption(assetName: "qs-rose", accessibilityName: "Rose")
  ]

  @Binding var selectedColor: String
  let accessibilityHint: LocalizedStringKey
  var isScreenStyled: Bool = true

  @ViewBuilder
  var body: some View {
    if isScreenStyled {
      swatches
        .sameLevelBorder(radius: 6, color: .black)
        .patternStyle()
        .cornerRadius(6)
    } else {
      swatches
    }
  }

  private var swatches: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(Self.defaultOptions) { option in
          swatchButton(for: option)
        }
      }
      .padding(2)
      .padding(.horizontal, 10)
    }
    .padding(.vertical)
    .scrollClipDisabled(true)
  }

  private func swatchButton(for option: ColorSwatchOption) -> some View {
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
    .accessibilityHint(Text(accessibilityHint))
    .accessibilityAddTraits(selectedColor == option.assetName ? .isSelected : [])
  }
}
