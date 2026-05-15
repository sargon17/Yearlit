import SwiftUI

struct TwinkleImage: View {
    let name: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let position: CGPoint
    let scale: CGFloat
    let minOpacity: Double
    let maxOpacity: Double

    /// Respect Reduce Motion when possible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animated states
    @State private var currentOpacity: Double = 0.0
    @State private var currentBlur: Double = 0.0
    @State private var currentDX: CGFloat = 0
    @State private var currentDY: CGFloat = 0
    @State private var currentScaleJitter: CGFloat = 1.0
    @State private var currentRotation: Double = 0.0

    /// Task lifecycle
    @State private var twinkleTask: Task<Void, Never>? = nil

    // Effect ranges (keep subtle)
    private let blurRange: ClosedRange<Double> = 0.0 ... 2.0
    private let jitterRange: ClosedRange<CGFloat> = -6 ... 6
    private let scaleJitterRange: ClosedRange<CGFloat> = 0.95 ... 1.05
    private let rotationRange: ClosedRange<Double> = -5.0 ... 5.0

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
            .onAppear { startTwinkle() }
            .onDisappear { stopTwinkle() }
    }

    private func startTwinkle() {
        // Avoid spawning multiple loops
        if twinkleTask == nil {
            twinkleTask = Task { await twinkleLoop() }
        }
    }

    private func stopTwinkle() {
        twinkleTask?.cancel()
        twinkleTask = nil
    }

    @MainActor
    private func twinkleLoop() async {
        // Reset to base state each time we (re)start
        currentOpacity = minOpacity
        currentBlur = 0
        currentDX = 0
        currentDY = 0
        currentScaleJitter = 1.0
        currentRotation = 0

        while !Task.isCancelled {
            let initialDelay = Double.random(in: 0.0 ... 1.2)
            try? await Task.sleep(nanoseconds: UInt64(initialDelay * 1_000_000_000))
            if Task.isCancelled { break }

            let rise = Double.random(in: 0.8 ... 1.8)
            let fall = Double.random(in: 0.8 ... 1.8)
            let wait = Double.random(in: 0.2 ... 1.2)
            let rest = Double.random(in: 0.3 ... 1.5)
            let peak = Double.random(in: minOpacity ... maxOpacity)

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
            if Task.isCancelled { break }

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

extension CGPoint {
    static func polar(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(
            x: center.x + CGFloat(cos(radians)) * radius,
            y: center.y + CGFloat(sin(radians)) * radius
        )
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

                    // Center & radii
                    let center = CGPoint(x: width * 0.5, y: height * 0.45)
                    let base = min(width, height)
                    let r1: CGFloat = base * 0.22
                    let r2: CGFloat = base * 0.34
                    let r3: CGFloat = base * 0.46

                    // Background concentric circles
                    Group {
                        Circle()
                            .stroke(.textPrimary.opacity(0.08), lineWidth: 1)
                            .frame(width: r1 * 2, height: r1 * 2)
                            .position(center)
                        Circle()
                            .stroke(.textPrimary.opacity(0.06), lineWidth: 1)
                            .frame(width: r2 * 2, height: r2 * 2)
                            .position(center)
                        Circle()
                            .stroke(.textPrimary.opacity(0.05), lineWidth: 1)
                            .frame(width: r3 * 2, height: r3 * 2)
                            .position(center)
                    }

                    // Center person icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.textPrimary.opacity(0.08))
                        .position(center)

                    // Ring 1 (inner) — 3 items
                    TwinkleImage(
                        name: "habit_06", // teeth brush
                        maxWidth: 70,
                        maxHeight: 100,
                        position: .polar(center: center, radius: r1, degrees: -20),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_07", // pen
                        maxWidth: 70,
                        maxHeight: 100,
                        position: .polar(center: center, radius: r1, degrees: 120),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_01", // calendar
                        maxWidth: 85,
                        maxHeight: 85,
                        position: .polar(center: center, radius: r1, degrees: 210),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )

                    // Ring 2 (middle) — 3 items
                    TwinkleImage(
                        name: "habit_02", // forks
                        maxWidth: 100,
                        maxHeight: 90,
                        position: .polar(center: center, radius: r2, degrees: 20),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_03", // scale
                        maxWidth: 100,
                        maxHeight: 90,
                        position: .polar(center: center, radius: r2, degrees: 155),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_08", // shoe
                        maxWidth: 100,
                        maxHeight: 90,
                        position: .polar(center: center, radius: r2, degrees: 260),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )

                    // Ring 3 (outer) — 3 items
                    TwinkleImage(
                        name: "habit_04", // watch
                        maxWidth: 90,
                        maxHeight: 80,
                        position: .polar(center: center, radius: r3, degrees: 70),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_05", // mat
                        maxWidth: 90,
                        maxHeight: 80,
                        position: .polar(center: center, radius: r3, degrees: 180),
                        scale: 0.6,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                    TwinkleImage(
                        name: "habit_09", // glass
                        maxWidth: 70,
                        maxHeight: 100,
                        position: .polar(center: center, radius: r3, degrees: 300),
                        scale: 0.5,
                        minOpacity: 0.0,
                        maxOpacity: 0.9
                    )
                }
            }
        } lower: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                Text("Don’t just set goals")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)

                VStack(alignment: .leading) {
                    Text("Decide the kind of person you want to be")
                    Text("👉 ‘I’m a reader’")
                    Text("👉 ‘I’m a runner’")
                    Text("👉 ‘I’m a learner’")
                }
                .multilineTextAlignment(.leading)
                .font(AppFont.mono(14))
                .foregroundStyle(.secondary)
            }
        }
    }
}
