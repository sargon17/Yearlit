import SwiftUI

struct NoiseOverlayModifier: ViewModifier {
  let opacity: CGFloat
  let blendMode: BlendMode

  init(opacity: CGFloat = 1, blendMode: BlendMode = .overlay) {
    self.opacity = opacity
    self.blendMode = blendMode
  }

  func body(content: Content) -> some View {
    content
    .background(
      Image("noise")
        .resizable(resizingMode: .tile)
        .blendMode(blendMode)
        .opacity(opacity)
        .allowsHitTesting(false)

    )
    .ignoresSafeArea(edges: .all)
  }
}

extension View {
  func noiseOverlay(opacity: CGFloat = 1, blendMode: BlendMode = .overlay) -> some View {
    modifier(NoiseOverlayModifier(opacity: opacity, blendMode: blendMode))
  }

  func surfaceBackground(
    _ color: Color,
    noiseOpacity: CGFloat = 1,
    blendMode: BlendMode = .overlay,
    ignoresSafeArea: Bool = false
  ) -> some View {
    background(
      Group {
        if ignoresSafeArea {
          color
            .overlay(
              Image("noise")
                .resizable(resizingMode: .tile)
                .blendMode(blendMode)
                .opacity(noiseOpacity)
                .allowsHitTesting(false)
            )
            .ignoresSafeArea(edges: .all)
        } else {
          color
            .overlay(
              Image("noise")
                .resizable(resizingMode: .tile)
                .blendMode(blendMode)
                .opacity(noiseOpacity)
                .allowsHitTesting(false)
            )
        }
      }
    )
  }
}
