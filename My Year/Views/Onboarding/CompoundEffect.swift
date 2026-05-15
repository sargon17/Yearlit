import SwiftUI

struct ExponentialGraph: View {
    @State private var progress: CGFloat = 0.0
    @State private var samples: [CGPoint] = []
    @State private var cumLen: [CGFloat] = []
    @State private var totalLen: CGFloat = 0

    private func f(_ x: CGFloat) -> CGFloat {
        // Stronger compounding
        let k: CGFloat = 6.0
        let num = exp(k * x) - 1
        let den = exp(k) - 1
        return num / den
    }

    private func rebuildTable(width w: CGFloat, height h: CGFloat, pad: CGFloat) {
        let gw = w - pad * 2
        let gh = h - pad * 2
        let steps = 600
        var pts: [CGPoint] = []
        pts.reserveCapacity(steps + 1)
        for i in 0 ... steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = f(t)
            pts.append(CGPoint(x: pad + gw * t, y: h - pad - gh * y))
        }
        // cumulative lengths
        var lens: [CGFloat] = Array(repeating: 0, count: pts.count)
        var acc: CGFloat = 0
        for i in 1 ..< pts.count {
            let dx = pts[i].x - pts[i - 1].x
            let dy = pts[i].y - pts[i - 1].y
            acc += sqrt(dx * dx + dy * dy)
            lens[i] = acc
        }
        samples = pts
        cumLen = lens
        totalLen = acc
    }

    private func point(at fraction: CGFloat) -> CGPoint {
        guard !samples.isEmpty, totalLen > 0 else { return .zero }
        let target = max(0, min(1, fraction)) * totalLen
        // binary search
        var lo = 0
        var hi = cumLen.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cumLen[mid] < target { lo = mid + 1 } else { hi = mid }
        }
        let i = max(1, lo)
        let l0 = cumLen[i - 1]
        let l1 = cumLen[i]
        let t: CGFloat = (l1 - l0) > 0 ? (target - l0) / (l1 - l0) : 0
        let p0 = samples[i - 1]
        let p1 = samples[i]
        return CGPoint(x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad: CGFloat = 16

            ZStack {
                // Axes
                Path { p in
                    // X axis
                    p.move(to: CGPoint(x: pad, y: h - pad))
                    p.addLine(to: CGPoint(x: w - pad, y: h - pad))
                    // Y axis
                    p.move(to: CGPoint(x: pad, y: h - pad))
                    p.addLine(to: CGPoint(x: pad, y: pad))
                }
                .stroke(.textPrimary.opacity(0.12), lineWidth: 1)

                // Exponential curve (drawn up to current arc-length fraction)
                Path { p in
                    guard !samples.isEmpty else { return }
                    p.move(to: samples.first!)
                    if totalLen <= 0 { return }
                    let target = max(0, min(1, progress)) * totalLen
                    // draw segments until target length
                    for i in 1 ..< samples.count {
                        if cumLen[i] <= target {
                            p.addLine(to: samples[i])
                        } else {
                            // interpolate last segment to target
                            let l0 = cumLen[i - 1]
                            let l1 = cumLen[i]
                            let t: CGFloat = (l1 - l0) > 0 ? (target - l0) / (l1 - l0) : 0
                            let p0 = samples[i - 1]
                            let p1 = samples[i]
                            let last = CGPoint(x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t)
                            p.addLine(to: last)
                            break
                        }
                    }
                }
                .stroke(.qsOrange.opacity(0.95), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .shadow(color: .qsOrange.opacity(0.35), radius: 6, x: 0, y: 2)

                // * Data label
                Text("37×")
                    .font(AppFont.mono(11))
                    .foregroundStyle(.secondary)
                    .position(x: w - pad - 22, y: pad + 6)
            }
            .animation(.linear(duration: 3.0), value: progress)
            .onAppear {
                print("appeared")

                rebuildTable(width: w, height: h, pad: pad)
                // Animate from 0 → 1 once the view appears
                progress = 0.0
                DispatchQueue.main.async {
                    progress = 1.0
                }
            }
        }
    }
}

struct CompoundEffect: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingView.OnboardingSlide(onNext: onNext) {
            GeometryReader { geometry in
                let height = geometry.size.height
                let width = geometry.size.width
                ZStack {
                    ExponentialGraph()
                        .frame(width: width * 0.9, height: height * 0.8)
                        .offset(x: width * 0.05, y: height * 0.1)
                }
            }
        } lower: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("The Compound Effect")
                    .font(AppFont.mono(24, weight: .black))
                    .foregroundStyle(.textPrimary)

                VStack(alignment: .leading) {
                    Text("1% better each day = 37x growth in a year.")
                    Text("Tiny actions → Massive change.")
                }
                .multilineTextAlignment(.leading)
                .font(AppFont.mono(14))
                .foregroundStyle(.secondary)
            }
        }
    }
}
