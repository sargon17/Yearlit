import Garnish
import SwiftUI

struct HabitsLoop: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingView.OnboardingSlide(onNext: onNext) {
            HabitLoopGraphic()
                .background(.surfaceMuted)
        } lower: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                Text("The Habit Loop")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(.textPrimary)

                VStack(alignment: .leading) {
                    Text("1. Cue")
                    Text("2. Craving")
                    Text("3. Action")
                    Text("4. Reward")
                }
                .multilineTextAlignment(.leading)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
            }
            .background(.surfaceMuted)
        }
    }
}

private struct HabitLoopGraphic: View {
    var body: some View {
        ZStack {
            SegmentedRing()
                .frame(maxWidth: 200, maxHeight: 200)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Four labels positioned around the ring
        .overlay(alignment: .topTrailing) {
            StepLabel("Cue")
                .padding(.top, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            StepLabel("Craving")
                .padding(.bottom, 16)
        }
        .overlay(alignment: .bottomLeading) {
            StepLabel("Action")
                .padding(.bottom, 16)
        }
        .overlay(alignment: .topLeading) {
            StepLabel("Reward")
                .padding(.top, 16)
        }
        .frame(maxWidth: 250, maxHeight: 250)
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct SegmentedRing: View {
    /// 4 equally spaced segments with distinct colors
    private let segments: [(start: CGFloat, end: CGFloat, color: Color)] = [
        (
            0.0, 0.25, try! GarnishColor.blend(.surfaceMuted, with: .qsOrange, ratio: 0.4)
        ), // Cue
        (
            0.25, 0.50, try! GarnishColor.blend(.surfaceMuted, with: .qsOrange, ratio: 0.6)
        ), // Craving
        (
            0.50, 0.75, try! GarnishColor.blend(.surfaceMuted, with: .qsOrange, ratio: 0.8)
        ), // Action
        (0.75, 1.00, .qsOrange), // Reward
    ]

    var body: some View {
        ZStack {
            ForEach(0 ..< segments.count, id: \.self) { i in
                let s = segments[i]
                Circle()
                    .trim(from: s.start, to: s.end)
                    .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .foregroundStyle(s.color)
                    .rotationEffect(.degrees(-90)) // start at top
            }
        }
    }
}

private struct StepLabel: View {
    let text: String
    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundStyle(.textPrimary)
    }
}
