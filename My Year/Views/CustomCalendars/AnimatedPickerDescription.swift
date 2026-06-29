import SwiftUI

struct AnimatedPickerDescription<ID: Hashable>: View {
  private let text: Text
  let id: ID
  var bottomPadding: CGFloat = 0

  init(text: String, id: ID, bottomPadding: CGFloat = 0) {
    self.text = Text(text)
    self.id = id
    self.bottomPadding = bottomPadding
  }

  init(text: LocalizedStringKey, id: ID, bottomPadding: CGFloat = 0) {
    self.text = Text(text)
    self.id = id
    self.bottomPadding = bottomPadding
  }

  var body: some View {
    ZStack(alignment: .leading) {
      text
        .font(.footnote)
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.bottom, bottomPadding)
        .id(id)
        .transition(.blurReplace.combined(with: .scale(scale: 0.98)))
    }
    .animation(.snappy, value: id)
  }
}
