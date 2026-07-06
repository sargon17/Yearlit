import SwiftUI

struct CalendarIdentityLCDSection: View {
  @Binding var name: String
  @Binding var selectedColor: String
  let prompt: String
  let isNameFocused: FocusState<Bool>.Binding

  var body: some View {
    CustomSection(label: "Calendar") {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Name")
            .labelStyle(type: .tertiary)

          TextField(
            "",
            text: $name,
            prompt: Text(prompt).foregroundColor(.white.opacity(0.2))
          )
          .focused(isNameFocused)
          .font(AppFont.mono(18, weight: .regular))
          .foregroundStyle(Color(selectedColor))
          .textInputAutocapitalization(.words)
        }
        .padding(14)

        Rectangle()
          .fill(Color.textTertiary.opacity(0.35))
          .frame(height: 1)

        VStack(alignment: .leading, spacing: 2) {
          Text("Color")
            .labelStyle(type: .tertiary)
            .padding(.horizontal, 14)
            .padding(.top, 12)

          ColorSwatchPicker(
            selectedColor: $selectedColor,
            accessibilityHint: "Select calendar color",
            isScreenStyled: false
          )
        }
        .padding(.bottom, 2)
      }
      .lcdScreenEffect(clipShape: RoundedRectangle(cornerRadius: 6), diffusion: 0.12, dotOpacity: 0.42)
      .sameLevelBorder(radius: 6, color: .black)
      .outerSameLevelShadow(radius: 6)
    }
  }
}
