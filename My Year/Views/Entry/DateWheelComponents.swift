import SwiftUI

struct CenterTrackedDateWheel: View {
  let offsets: [Int]
  @Binding var selectedOffset: Int
  let accentColor: Color
  let label: (Int) -> String

  @State private var lastHapticOffset: Int?
  @State private var selection: Int?

  private let rowHeight: CGFloat = 44

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - rowHeight) / 2)

      ScrollView(.vertical) {
        LazyVStack(spacing: 0) {
          ForEach(offsets, id: \.self) { offset in
            row(for: offset)
          }
        }
        .scrollTargetLayout()
        .padding(.vertical, verticalPadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .scrollTargetBehavior(.viewAligned)
      .mask { WheelFadeMask() }
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if selectedOffset != newValue {
          selectedOffset = newValue
        }
        if newValue != lastHapticOffset {
          lastHapticOffset = newValue
          Task {
            await hapticFeedback(.light)
          }
        }
      }
      .onChange(of: selectedOffset) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = selectedOffset
        lastHapticOffset = selectedOffset
      }
    }
  }

  private func row(for offset: Int) -> some View {
    Text(label(offset))
      .font(AppFont.mono(18, weight: .bold))
      .foregroundStyle(offset == selectedOffset ? accentColor : .textSecondary)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .frame(maxWidth: .infinity)
      .frame(height: rowHeight)
      .id(offset)
      .scrollTransition(.interactive, axis: .vertical) { content, phase in
        content
          .opacity(phase.isIdentity ? 1 : 0.48)
          .rotation3DEffect(
            .degrees(Double(phase.value) * -28),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.55
          )
      }
  }
}

struct WheelFadeMask: View {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: .clear, location: 0),
        .init(color: .black, location: 0.18),
        .init(color: .black, location: 0.82),
        .init(color: .clear, location: 1)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}
