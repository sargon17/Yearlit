import SharedModels
import SwiftUI

struct GridDot: View {
  let color: Color
  let dotSize: CGFloat

  init(color: Color, dotSize: CGFloat) {
    self.color = color
    self.dotSize = dotSize
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(
        color
      )
      .frame(width: dotSize, height: dotSize)
  }
}
