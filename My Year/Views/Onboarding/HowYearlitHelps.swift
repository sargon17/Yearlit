import SwiftUI

struct HowYearlitHelps: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingView.OnboardingSlide(onNext: onNext) {
            // Animated grid for visual interest
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let topInset = proxy.safeAreaInsets.top
                let ratio = Double(height / width)

                let columns: Double = 16
                let rows = Int(columns * ratio)

                ZStack { // container to control safe-area + clipping
                    PhasedOpacityGrid(rows: rows, cols: Int(columns), spacing: 8, speed: 1.8)
                        // extend the drawing area to include the top safe-area and pull it up
                        .frame(height: height + topInset)
                        .padding(.horizontal, 8)
                        .scaleEffect(1.6)
                        .rotationEffect(Angle(degrees: 18))
                }
                // Let the artwork render under the status bar only on this slide
                .ignoresSafeArea(.container, edges: .top)
                // Clip to this view's horizontal bounds so it doesn't bleed into other slides
                .mask(
                    Rectangle()
                        .padding(.vertical, -height * 0.15) // don’t clip top/bottom, only left/right
                )
            }
        } lower: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("How Yearlit Helps You")
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)

                // To make habits stick, keep them:
                VStack(alignment: .leading) {
                    Text("📅 One dot = one day")
                    Text("🔥 See your streaks grow")
                    Text("📊 Spot patterns at a glance")
                }
                .multilineTextAlignment(.leading)
                .font(AppFont.mono(14))
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PhasedOpacityGrid: View {
    let rows: Int
    let cols: Int
    let spacing: CGFloat
    let speed: Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
            let t = -1 * context.date.timeIntervalSinceReferenceDate
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: cols),
                spacing: spacing
            ) {
                ForEach(0 ..< (rows * cols), id: \.self) { i in
                    let r = i / cols
                    let c = i % cols
                    let centerR = (Double(rows) - 1) / 2
                    let centerC = (Double(cols) - 1) / 2
                    // radial phase offset so waves travel from center outward
                    let dist = hypot(Double(r) - centerR, Double(c) - centerC)
                    let phase = dist * 0.6
                    // animate opacity with a smooth 0...1 sine wave
                    let raw = sin(t * speed + phase)
                    let normalized = (raw + 1) / 2 // 0...1
                    let opacity = 0.15 + 0.85 * normalized // keep a faint minimum so squares are always visible

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brand.opacity(opacity))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            // Removed trailing animation modifier
        }
    }
}
