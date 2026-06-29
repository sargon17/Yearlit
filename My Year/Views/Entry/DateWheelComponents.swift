import SwiftUI

struct CenterTrackedDateWheel: View {
  let offsets: [Int]
  @Binding var selectedOffset: Int
  let accentColor: Color
  let label: (Int) -> String

  @State private var lastHapticOffset: Int?
  @State private var isReadyForGeometrySelection = false

  private let rowHeight: CGFloat = 44
  private let coordinateSpaceName = "date-wheel-scroll"

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - rowHeight) / 2)
      let centerY = geometry.size.height / 2

      ScrollViewReader { proxy in
        ScrollView(.vertical) {
          LazyVStack(spacing: 0) {
            ForEach(offsets, id: \.self) { offset in
              row(for: offset)
            }
          }
          .padding(.vertical, verticalPadding)
        }
        .coordinateSpace(name: coordinateSpaceName)
        .scrollIndicators(.hidden)
        .mask { WheelFadeMask() }
        .onPreferenceChange(DateWheelRowCentersPreferenceKey.self) { centers in
          guard isReadyForGeometrySelection else { return }
          updateSelection(from: centers, centerY: centerY)
        }
        .onAppear {
          isReadyForGeometrySelection = false
          proxy.scrollTo(selectedOffset, anchor: .center)
          lastHapticOffset = selectedOffset
          Task { @MainActor in
            isReadyForGeometrySelection = true
          }
        }
        .onChange(of: selectedOffset) { _, newValue in
          isReadyForGeometrySelection = false
          proxy.scrollTo(newValue, anchor: .center)
          Task { @MainActor in
            isReadyForGeometrySelection = true
          }
        }
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
      .background {
        GeometryReader { rowGeometry in
          Color.clear.preference(
            key: DateWheelRowCentersPreferenceKey.self,
            value: [offset: rowGeometry.frame(in: .named(coordinateSpaceName)).midY]
          )
        }
      }
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

  private func updateSelection(from centers: [Int: CGFloat], centerY: CGFloat) {
    guard
      let closest = centers.min(by: { lhs, rhs in
        abs(lhs.value - centerY) < abs(rhs.value - centerY)
      })?.key
    else {
      return
    }
    guard closest != selectedOffset else { return }
    selectedOffset = closest
    if closest != lastHapticOffset {
      lastHapticOffset = closest
      Task {
        await hapticFeedback(.light)
      }
    }
  }
}

private struct DateWheelRowCentersPreferenceKey: PreferenceKey {
  static var defaultValue: [Int: CGFloat] = [:]

  static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
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
