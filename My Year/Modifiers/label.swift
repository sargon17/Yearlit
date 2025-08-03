import SwiftUI

enum LabelType {
  case primary
  case secondary
  case tertiary

  var color: Color {
    switch self {
    case .primary:
      return .textPrimary
    case .secondary:
      return .textSecondary
    case .tertiary:
      return .textTertiary
    }
  }
}

struct LabelModifier: ViewModifier {
  let type: LabelType

  func body(content: Content) -> some View {
    content
      .font(.system(size: 12, design: .monospaced).weight(.semibold))
      .foregroundStyle(type.color)
  }
}

extension View {
  func labelStyle(type: LabelType) -> some View {
    self.modifier(LabelModifier(type: type))
  }
}
