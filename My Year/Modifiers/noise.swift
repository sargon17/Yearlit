import SwiftUI

enum SurfaceMaterial {
  case noise
  case roughPlastic
}

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

  private var resolvedOpacity: CGFloat {
    if opacity != 1 {
      return opacity
    }

    return colorScheme == .light ? 0.5 : 1
  }

  var body: some View {
    Image("noise")
      .resizable(resizingMode: .tile)
      .blendMode(resolvedBlendMode)
      .opacity(resolvedOpacity)
      .allowsHitTesting(false)
  }
}

struct RoughPlasticLayer: View {
  let strength: CGFloat
  let blendMode: BlendMode?

  @Environment(\.colorScheme) private var colorScheme

  private var clampedStrength: CGFloat {
    min(1, max(0, strength))
  }

  private var grainOpacity: CGFloat {
    (colorScheme == .light ? 0.06 : 0.05) * clampedStrength
  }

  private var grainBlendMode: BlendMode {
    if let blendMode {
      return blendMode
    }
    return colorScheme == .light ? .softLight : .overlay
  }

  var body: some View {
    ZStack {
      PlasticUnevennessLayer()
        .opacity((colorScheme == .light ? 0.36 : 0.28) * clampedStrength)

      NoiseLayer(opacity: grainOpacity, blendMode: grainBlendMode)

      PlasticSpeckleLayer(
        color: colorScheme == .light ? .black : .white,
        spacing: 7,
        dotSize: colorScheme == .light ? 0.62 : 0.5
      )
      .opacity((colorScheme == .light ? 0.12 : 0.09) * clampedStrength)
      .blendMode(colorScheme == .light ? .multiply : .screen)

      PlasticFiberLayer(color: colorScheme == .light ? .black : .white)
        .opacity((colorScheme == .light ? 0.08 : 0.07) * clampedStrength)
        .blendMode(colorScheme == .light ? .multiply : .screen)
    }
    .compositingGroup()
    .allowsHitTesting(false)
  }
}

private struct PlasticUnevennessLayer: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color.white.opacity(colorScheme == .dark ? 0.018 : 0.026),
          Color.clear,
          Color.black.opacity(colorScheme == .dark ? 0.055 : 0.026)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      RadialGradient(
        colors: [
          Color.white.opacity(colorScheme == .dark ? 0.012 : 0.018),
          Color.clear
        ],
        center: .topLeading,
        startRadius: 0,
        endRadius: 380
      )
    }
  }
}

private struct PlasticSpeckleLayer: View {
  let color: Color
  let spacing: CGFloat
  let dotSize: CGFloat

  var body: some View {
    GeometryReader { geometry in
      let columns = max(1, Int(geometry.size.width / spacing))
      let rows = max(1, Int(geometry.size.height / spacing))

      Path { path in
        for row in 0...rows {
          for column in 0...columns {
            let seed = (row * 73) + (column * 37)
            guard seed % 4 == 0 else { continue }

            let x = CGFloat(column) * spacing + CGFloat(seed % 5) - 2
            let y = CGFloat(row) * spacing + CGFloat((seed / 3) % 5) - 2

            path.addEllipse(
              in: CGRect(
                x: x,
                y: y,
                width: dotSize,
                height: dotSize
              )
            )
          }
        }
      }
      .fill(color)
    }
  }
}

private struct PlasticFiberLayer: View {
  let color: Color

  var body: some View {
    GeometryReader { geometry in
      let spacing: CGFloat = 13
      let columns = max(1, Int(geometry.size.width / spacing))
      let rows = max(1, Int(geometry.size.height / spacing))

      Path { path in
        for row in 0...rows {
          for column in 0...columns {
            let seed = (row * 89) + (column * 41)
            guard seed % 5 == 0 else { continue }

            let x = CGFloat(column) * spacing + CGFloat(seed % 9) - 4
            let y = CGFloat(row) * spacing + CGFloat((seed / 5) % 9) - 4
            let length = CGFloat(2 + seed % 8)
            let isHorizontal = seed % 3 != 0

            path.move(to: CGPoint(x: x, y: y))
            path.addLine(
              to: CGPoint(
                x: x + (isHorizontal ? length : length * 0.35),
                y: y + (isHorizontal ? length * 0.12 : length)
              )
            )
          }
        }
      }
      .stroke(color, lineWidth: 0.45)
    }
  }
}

struct SurfaceBackgroundModifier: ViewModifier {
  let color: Color
  let noiseOpacity: CGFloat
  let blendMode: BlendMode?
  let material: SurfaceMaterial
  let ignoresSafeArea: Bool

  func body(content: Content) -> some View {
    content
      .background(
        Group {
          if ignoresSafeArea {
            surface
              .ignoresSafeArea(edges: .all)
          } else {
            surface
          }
        }
      )
  }

  private var surface: some View {
    color
      .overlay(materialLayer)
  }

  @ViewBuilder
  private var materialLayer: some View {
    switch material {
    case .noise:
      NoiseLayer(opacity: noiseOpacity, blendMode: blendMode)
    case .roughPlastic:
      RoughPlasticLayer(strength: noiseOpacity, blendMode: blendMode)
    }
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
    material: SurfaceMaterial = .roughPlastic,
    ignoresSafeArea: Bool = false
  ) -> some View {
    modifier(
      SurfaceBackgroundModifier(
        color: color,
        noiseOpacity: noiseOpacity,
        blendMode: blendMode,
        material: material,
        ignoresSafeArea: ignoresSafeArea
      )
    )
  }
}
