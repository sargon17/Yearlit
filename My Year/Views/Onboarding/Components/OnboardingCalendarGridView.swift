import Garnish
import SwiftUI

struct OnboardingCalendarGridView: View {
  private let columns = 10
  private let dotSize: CGFloat = 58
  private let spacing: CGFloat = 18
  private let dotCornerRadius: CGFloat = 9
  private let valueHoldDuration: Double = 3.2
  private let valueTransitionDuration: Double = 0.55

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.onboardingAccent) private var accent

  var body: some View {
    GeometryReader { proxy in
      let width = max(proxy.size.width, 1)
      let height = max(proxy.size.height, 1)
      let rowStride = dotSize + spacing
      let minimumRows = Int(ceil((height * 1.45) / rowStride))
      let rows = max(minimumRows, columns + 4)
      let centerRow = rows / 2
      let centerColumn = columns / 2
      let todayIndex = index(row: centerRow, column: centerColumn)

      timelineGrid(
        rows: rows,
        todayIndex: todayIndex,
        centerRow: centerRow,
        centerColumn: centerColumn,
        width: width,
        height: height
      )
      .ignoresSafeArea(.container, edges: .top)
      .mask(
        Rectangle()
          .padding(.vertical, -height * 0.15)
      )
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private func timelineGrid(
    rows: Int,
    todayIndex: Int,
    centerRow: Int,
    centerColumn: Int,
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    if reduceMotion {
      grid(
        rows: rows,
        todayIndex: todayIndex,
        centerRow: centerRow,
        centerColumn: centerColumn,
        width: width,
        height: height,
        time: 0
      )
    } else {
      TimelineView(.periodic(from: .now, by: 1.0 / 24.0)) { context in
        grid(
          rows: rows,
          todayIndex: todayIndex,
          centerRow: centerRow,
          centerColumn: centerColumn,
          width: width,
          height: height,
          time: context.date.timeIntervalSinceReferenceDate
        )
      }
    }
  }

  private func grid(
    rows: Int,
    todayIndex: Int,
    centerRow: Int,
    centerColumn: Int,
    width: CGFloat,
    height: CGFloat,
    time: TimeInterval
  ) -> some View {
    ZStack {
      ForEach(0..<(rows * columns), id: \.self) { index in
        let row = index / columns
        let column = index % columns
        let x = (width / 2) + CGFloat(column - centerColumn) * (dotSize + spacing)
        let y = (height / 2) + CGFloat(row - centerRow) * (dotSize + spacing)

        RoundedRectangle(cornerRadius: dotCornerRadius)
          .fill(color(for: index, todayIndex: todayIndex, time: time))
          .frame(width: dotSize, height: dotSize)
          .position(x: x, y: y)
      }
    }
    .rotationEffect(.degrees(11), anchor: .center)
    .scaleEffect(1.08, anchor: .center)
  }

  private func color(for index: Int, todayIndex: Int, time: TimeInterval) -> Color {
    if index == todayIndex {
      return activeDayColor()
    }

    if index > todayIndex {
      return futureDayColor()
    }

    return simulatedTrackedColor(for: index, time: time)
  }

  private func simulatedTrackedColor(for index: Int, time: TimeInterval) -> Color {
    let stagger = Double(index % 11) * 0.17
    let localTime = time + stagger
    let cycle = floor(localTime / valueHoldDuration)
    let progress = (localTime / valueHoldDuration) - cycle
    let transitionProgress = min(1, progress / valueTransitionDuration)
    let easedProgress = transitionProgress * transitionProgress * (3 - (2 * transitionProgress))

    let previousRatio = simulatedCompletionRatio(for: index, cycle: Int(cycle) - 1)
    let nextRatio = simulatedCompletionRatio(for: index, cycle: Int(cycle))
    let animatedRatio = previousRatio + ((nextRatio - previousRatio) * easedProgress)

    return GarnishColor.blend(missedDayColor(), with: accent, ratio: animatedRatio)
  }

  private func simulatedCompletionRatio(for index: Int, cycle: Int) -> Double {
    let stateValue = deterministicUnitValue(seed: (index * 19) + (cycle * 29))
    guard stateValue > 0.24 else { return 0 }

    let baseRatio = simulatedCompletionRatios[index % simulatedCompletionRatios.count]
    let variation = deterministicUnitValue(seed: (index * 31) + (cycle * 17))
    return min(1, max(0.35, baseRatio + ((variation - 0.5) * 0.44)))
  }

  private func deterministicUnitValue(seed: Int) -> Double {
    let value = abs(sin(Double(seed) * 12.9898) * 43_758.5453)
    return value - floor(value)
  }

  private func index(row: Int, column: Int) -> Int {
    (row * columns) + column
  }

  private var simulatedCompletionRatios: [Double] {
    [1, 0.72, 0.42, 0.88, 0.55, 1, 0.35, 0.78, 0.48, 0.94, 0.62, 0.4]
  }
}
