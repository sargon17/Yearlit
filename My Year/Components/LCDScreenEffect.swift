import SwiftUI

struct LCDScreenEffect<ClipShape: Shape>: ViewModifier {
  let clipShape: ClipShape
  var diffusion: CGFloat = 0.14
  var dotOpacity: Double = 0.32

  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .background(
        LinearGradient(
          colors: [
            Color.black.opacity(colorScheme == .dark ? 0.995 : 0.985),
            Color.black.opacity(colorScheme == .dark ? 0.985 : 0.965)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .compositingGroup()
      .blur(radius: diffusion)
      .overlay {
        LCDDotTexture()
          .opacity(dotOpacity)
          .allowsHitTesting(false)
      }
      .overlay {
        LCDGlassLayer()
          .allowsHitTesting(false)
      }
      .clipShape(clipShape)
  }
}

extension View {
  func lcdScreenEffect<ClipShape: Shape>(
    clipShape: ClipShape,
    diffusion: CGFloat = 0.14,
    dotOpacity: Double = 0.32
  ) -> some View {
    modifier(LCDScreenEffect(clipShape: clipShape, diffusion: diffusion, dotOpacity: dotOpacity))
  }
}

private struct LCDDotTexture: View {
  var body: some View {
    GeometryReader { geometry in
      let spacing: CGFloat = 4
      let columns = Int(geometry.size.width / spacing)
      let rows = Int(geometry.size.height / spacing)

      Path { path in
        for column in 0...columns {
          for row in 0...rows {
            let origin = CGPoint(x: CGFloat(column) * spacing, y: CGFloat(row) * spacing)
            path.addRect(CGRect(origin: origin, size: CGSize(width: 1.15, height: 1.15)))
          }
        }
      }
      .fill(Color.white.opacity(0.14))
    }
  }
}

private struct LCDGlassLayer: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        LinearGradient(
          colors: [
            Color.white.opacity(colorScheme == .dark ? 0.035 : 0.055),
            Color.white.opacity(colorScheme == .dark ? 0.008 : 0.016),
            Color.clear,
            Color.black.opacity(colorScheme == .dark ? 0.16 : 0.11)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        VStack(spacing: 3) {
          ForEach(0..<120, id: \.self) { _ in
            Rectangle()
              .fill(Color.white.opacity(colorScheme == .dark ? 0.014 : 0.02))
              .frame(height: 1)
            Rectangle()
              .fill(Color.clear)
              .frame(height: 2)
          }
        }

        Capsule()
          .fill(Color.white.opacity(colorScheme == .dark ? 0.035 : 0.05))
          .frame(
            width: max(84, geometry.size.width * 0.52),
            height: max(12, geometry.size.height * 0.16)
          )
          .blur(radius: 7)
          .rotationEffect(.degrees(-18))
          .position(
            x: geometry.size.width * 0.24,
            y: geometry.size.height * 0.22
          )

        Capsule()
          .fill(Color.white.opacity(colorScheme == .dark ? 0.014 : 0.024))
          .frame(
            width: max(60, geometry.size.width * 0.34),
            height: max(8, geometry.size.height * 0.1)
          )
          .blur(radius: 6)
          .rotationEffect(.degrees(-18))
          .position(
            x: geometry.size.width * 0.78,
            y: geometry.size.height * 0.68
          )
      }
    }
    .compositingGroup()
    .blur(radius: 0.12)
  }
}
