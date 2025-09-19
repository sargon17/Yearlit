import SwiftUI

struct H4Modifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .textDefault()
      .fontWeight(.bold)
  }
}
extension View {
  func h4() -> some View {
    modifier(H4Modifier())
  }
}

struct BodyModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .textDefault()
      .font(.system(size: 12))
      .foregroundStyle(.textSecondary)
  }
}

extension View {
  func body() -> some View {
    modifier(BodyModifier())
  }
}

struct CaptionModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .textDefault()
      .font(.system(size: 10))
      .foregroundStyle(.textSecondary)
  }
}

extension View {
  func caption() -> some View {
    modifier(CaptionModifier())
  }
}

struct TextDefaultModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .fontDesign(.monospaced)
  }
}
extension View {
  func textDefault() -> some View {
    modifier(TextDefaultModifier())
  }
}
