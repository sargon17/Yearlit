import SwiftUI

struct CustomSection<Content: View>: View {
  let content: () -> Content
  let label: String

  init(label: String = "", @ViewBuilder content: @escaping () -> Content) {
    self.label = label
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(label)
        .font(.system(size: 12, design: .monospaced).weight(.semibold))
        .foregroundStyle(.textTertiary)

      content()
    }
  }
}
