import SharedModels
import SwiftUI

struct WidgetPreviewFrame<Content: View>: View {
  @Environment(\.colorScheme) private var colorScheme

  let family: WidgetPreviewFamily
  var width: CGFloat?
  @ViewBuilder let content: () -> Content

  private var canonicalSize: CGSize {
    switch family {
    case .small:
      return CGSize(width: 158, height: 158)
    case .medium:
      return CGSize(width: 338, height: 158)
    case .large:
      return CGSize(width: 338, height: 354)
    }
  }

  private var size: CGSize {
    guard let width else { return canonicalSize }
    return CGSize(width: width, height: width * canonicalSize.height / canonicalSize.width)
  }

  private var shadowColor: Color {
    colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.14)
  }

  var body: some View {
    content()
      .frame(width: size.width, height: size.height)
      .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), lineWidth: 0.5)
      }
      .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
  }
}
