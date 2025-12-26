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

struct NoiseLayer: View {
  let opacity: CGFloat
  let blendMode: BlendMode?

  @Environment(\.colorScheme) private var colorScheme

  private var resolvedBlendMode: BlendMode {
    if let blendMode {
      return blendMode
    }
    return colorScheme == .light ? .colorBurn : .overlay
  }

  var body: some View {
    Image("noise")
      .resizable(resizingMode: .tile)
      .blendMode(resolvedBlendMode)
      .opacity(opacity)
      .allowsHitTesting(false)
  }
}

struct SurfaceBackgroundModifier: ViewModifier {
  let color: Color
  let noiseOpacity: CGFloat
  let blendMode: BlendMode?
  let ignoresSafeArea: Bool

  func body(content: Content) -> some View {
    content
      .background(
        Group {
          if ignoresSafeArea {
            color
              .overlay(NoiseLayer(opacity: noiseOpacity, blendMode: blendMode))
              .ignoresSafeArea(edges: .all)
          } else {
            color
              .overlay(NoiseLayer(opacity: noiseOpacity, blendMode: blendMode))
          }
        }
      )
  }
}

extension View {
  func noiseOverlay(opacity: CGFloat = 1, blendMode: BlendMode = .overlay) -> some View {
    modifier(NoiseOverlayModifier(opacity: opacity, blendMode: blendMode))
  }

  func surfaceBackground(
    _ color: Color,
    noiseOpacity: CGFloat = 1,
    blendMode: BlendMode? = nil,
    ignoresSafeArea: Bool = false
  ) -> some View {
    modifier(
      SurfaceBackgroundModifier(
        color: color,
        noiseOpacity: noiseOpacity,
        blendMode: blendMode,
        ignoresSafeArea: ignoresSafeArea
      )
    )
  }
}
