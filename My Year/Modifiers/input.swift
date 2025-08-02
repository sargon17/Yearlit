import SwiftUI

enum InputSize {
  case small
  //   case medium
  case large
}

struct InputModifier: ViewModifier {
  let size: InputSize
  let radius: CGFloat

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .sameLevelBorder(radius: radius, color: .black)
      .outerSameLevelShadow(radius: radius)
      .foregroundColor(Color.orange)
      .font(.system(size: fontSize, weight: .regular, design: .monospaced))
      .patternStyle()
      .cornerRadius(radius)
      .accentColor(.orange)
  }

  var padding: CGFloat {
    switch size {
    case .small:
      return 4
    case .large:
      return 12
    }
  }

  var fontSize: CGFloat {
    switch size {
    case .small:
      return 12
    case .large:
      return 16
    }
  }
}

extension View {
  func inputStyle(size: InputSize = .large, radius: CGFloat = 6) -> some View {
    self.modifier(InputModifier(size: size, radius: radius))
  }
}
