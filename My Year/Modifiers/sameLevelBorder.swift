import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
  private let motionManager = CMMotionManager()
  @Published var x: CGFloat = 0.0
  @Published var y: CGFloat = 0.0

  init() {
    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data: CMDeviceMotion?, error) in
      guard let self = self, let motion = data?.attitude else { return }
      self.x = motion.roll
      self.y = motion.pitch
    }
  }
}

struct SameLevelBorder: ViewModifier {
  @StateObject private var motionManager = MotionManager()
  let radius: CGFloat
  let color: Color

  init(radius: CGFloat = 4, color: Color = .surfaceMuted) {
    self.radius = radius
    self.color = color
  }

  func body(content: Content) -> some View {
    ZStack {
      content
    }
    .background(
      RoundedRectangle(cornerRadius: radius)
        .foregroundStyle(
          color
            .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: motionManager.x, y: motionManager.y))  // inner light shadow
            .shadow(.inner(color: .black.opacity(0.1), radius: 1, x: motionManager.x, y: motionManager.y))  // inner dark shadow
        )
    )
    .background(
      RoundedRectangle(cornerRadius: radius)
        .stroke(getVoidColor(), lineWidth: 1)
    )
  }

}

func getVoidColor() -> Color {
  @Environment(\.colorScheme) var colorScheme
  return colorScheme == .dark ? .black.opacity(0.8) : .black.opacity(0.4)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted) -> some View {
    self.modifier(SameLevelBorder(radius: radius, color: color))
  }
}

struct OuterSameLevelShadow: ViewModifier {
  @StateObject private var motionManager = MotionManager()
  let radius: CGFloat

  init(radius: CGFloat = 4) {
    self.radius = radius
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(
            .surfaceMuted
              .shadow(.drop(color: .white.opacity(0.1), radius: 1, x: motionManager.x, y: motionManager.y))
              .shadow(.drop(color: .black.opacity(0.1), radius: 1, x: motionManager.x, y: motionManager.y))
          )
      )
  }
}

extension View {
  func outerSameLevelShadow(radius: CGFloat = 6) -> some View {
    self.modifier(OuterSameLevelShadow(radius: radius))
  }
}
