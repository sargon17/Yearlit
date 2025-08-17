import SwiftUI

struct TwinkleImage: View {
  let name: String
  let maxWidth: CGFloat
  let maxHeight: CGFloat
  let position: CGPoint
  let scale: CGFloat
  let minOpacity: Double
  let maxOpacity: Double

  // Respect Reduce Motion when possible
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // Animated states
  @State private var currentOpacity: Double = 0.0
  @State private var currentBlur: Double = 0.0
  @State private var currentDX: CGFloat = 0
  @State private var currentDY: CGFloat = 0
  @State private var currentScaleJitter: CGFloat = 1.0
  @State private var currentRotation: Double = 0.0

  // Effect ranges (keep subtle)
  private let blurRange: ClosedRange<Double> = 0.0...2.0
  private let jitterRange: ClosedRange<CGFloat> = (-6)...(6)
  private let scaleJitterRange: ClosedRange<CGFloat> = 0.95...1.05
  private let rotationRange: ClosedRange<Double> = -5.0...5.0

  var body: some View {
    Image(name)
      .resizable()
      .frame(maxWidth: maxWidth, maxHeight: maxHeight)
      .opacity(currentOpacity)
      .blur(radius: currentBlur)
      .scaleEffect(scale * currentScaleJitter)
      .rotationEffect(.degrees(currentRotation))
      .position(position)
      .offset(x: currentDX, y: currentDY)
      .compositingGroup()
      .task { await twinkleLoop() }
  }

  @MainActor
  private func twinkleLoop() async {
    // Start from base state
    currentOpacity = minOpacity
    currentBlur = 0
    currentDX = 0
    currentDY = 0
    currentScaleJitter = 1.0
    currentRotation = 0

    while true {
      let initialDelay = Double.random(in: 0.0...1.2)
      try? await Task.sleep(nanoseconds: UInt64(initialDelay * 1_000_000_000))

      let rise = Double.random(in: 0.8...1.8)
      let fall = Double.random(in: 0.8...1.8)
      let wait = Double.random(in: 0.2...1.2)
      let rest = Double.random(in: 0.3...1.5)
      let peak = Double.random(in: minOpacity...maxOpacity)

      // Random targets for this pulse (kept subtle)
      let targetBlur = reduceMotion ? 0 : Double.random(in: blurRange)
      let targetDX = reduceMotion ? 0 : CGFloat.random(in: jitterRange)
      let targetDY = reduceMotion ? 0 : CGFloat.random(in: jitterRange)
      let targetScale = reduceMotion ? 1.0 : CGFloat.random(in: scaleJitterRange)
      let targetRotation = reduceMotion ? 0 : Double.random(in: rotationRange)

      withAnimation(.easeInOut(duration: rise)) {
        currentOpacity = peak
        currentBlur = targetBlur
        currentDX = targetDX
        currentDY = targetDY
        currentScaleJitter = targetScale
        currentRotation = targetRotation
      }
      try? await Task.sleep(nanoseconds: UInt64((rise + wait) * 1_000_000_000))

      withAnimation(.easeInOut(duration: fall)) {
        currentOpacity = minOpacity
        currentBlur = 0
        currentDX = 0
        currentDY = 0
        currentScaleJitter = 1.0
        currentRotation = 0
      }
      try? await Task.sleep(nanoseconds: UInt64(rest * 1_000_000_000))
    }
  }
}

struct IdentityFirst: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: onNext) {
      ZStack {
        GeometryReader { proxy in
          let height = proxy.size.height
          let width = proxy.size.width

          TwinkleImage(
            name: "habit_01",
            maxWidth: 85,
            maxHeight: 85,
            position: CGPoint(x: width * 0.9, y: height * 0.9),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_02",
            maxWidth: 100,
            maxHeight: 90,
            position: CGPoint(x: width * 0.8, y: height * 0.3),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_03",
            maxWidth: 100,
            maxHeight: 90,
            position: CGPoint(x: width * 0.4, y: height * 0.75),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_04",
            maxWidth: 90,
            maxHeight: 80,
            position: CGPoint(x: width * 0.1, y: height * 0.45),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_05",
            maxWidth: 90,
            maxHeight: 80,
            position: CGPoint(x: width * 0.2, y: height * 0.1),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_06",
            maxWidth: 70,
            maxHeight: 100,
            position: CGPoint(x: width * 0.5, y: height * 0.45),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_07",
            maxWidth: 70,
            maxHeight: 100,
            position: CGPoint(x: width * 0.75, y: height * 0.65),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_08",
            maxWidth: 100,
            maxHeight: 90,
            position: CGPoint(x: width * 0.1, y: height * 0.85),
            scale: 1.0,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

          TwinkleImage(
            name: "habit_09",
            maxWidth: 70,
            maxHeight: 100,
            position: CGPoint(x: width * 0.53, y: height * 0.18),
            scale: 0.9,
            minOpacity: 0.0,
            maxOpacity: 0.9
          )

        }
      }
    } lower: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()

        Text("Don’t just set goals")
          .font(.system(size: 24, weight: .black, design: .monospaced))
          .foregroundStyle(.textPrimary)

        VStack(alignment: .leading) {
          Text("Decide the kind of person you want to be")
          Text("👉 ‘I’m a reader’")
          Text("👉 ‘I’m a runner’")
          Text("👉 ‘I’m a learner’")
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.secondary)
      }
    }
  }
}
