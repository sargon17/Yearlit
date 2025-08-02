import SwiftUI

struct PatternModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .overlay(
        // Tech pixel screen pattern overlay
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.black, lineWidth: 1)
          .overlay(
            GeometryReader { geometry in
              let size = geometry.size
              let spacing: CGFloat = 4
              let columns = Int(size.width / spacing)
              let rows = Int(size.height / spacing)
              Path { path in
                for col in 0...columns {
                  for row in 0...rows {
                    let xPos = CGFloat(col) * spacing
                    let yPos = CGFloat(row) * spacing
                    path.addRect(CGRect(x: xPos, y: yPos, width: 1, height: 1))
                  }
                }
              }
              .fill(Color.white.opacity(0.1))
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
          )
      )

  }
}

extension View {
  func patternStyle() -> some View {
    self.modifier(PatternModifier())
  }
}
