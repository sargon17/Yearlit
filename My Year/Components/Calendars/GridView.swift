import SharedModels
import SwiftUI

struct GridView: View {
  let handleDayTap: (Date) -> Void
  let days: [CalendarGridDay]
  let rippleOriginDate: Date?
  let rippleTrigger: Int

  init(
    handleDayTap: @escaping (Date) -> Void,
    days: [CalendarGridDay],
    rippleOriginDate: Date? = nil,
    rippleTrigger: Int = 0
  ) {
    self.handleDayTap = handleDayTap
    self.days = days
    self.rippleOriginDate = rippleOriginDate
    self.rippleTrigger = rippleTrigger
  }

  var body: some View {
    GeometryReader { geometry in
      let layout = CalendarGridLayout(size: geometry.size, dayCount: days.count)
      gridRows(layout: layout)
    }
  }

  private func gridRows(layout: CalendarGridLayout) -> some View {
    let rippleOriginIndex = rippleOriginIndex()

    return VStack(spacing: layout.verticalSpacing) {
      ForEach(0..<layout.rows, id: \.self) { row in
        HStack(spacing: layout.horizontalSpacing) {
          ForEach(0..<layout.columns, id: \.self) { col in
            let day = layout.index(row: row, column: col)
            if day < days.count {
              let dayData = days[day]
              let ripple = CalendarGridRipple(index: day, originIndex: rippleOriginIndex, columns: layout.columns)

              TappableGridDot(
                color: dayData.color,
                colorSaturation: dayData.colorSaturation,
                dotSize: layout.dotSize,
                hitSize: layout.hitSize,
                isDisabled: dayData.isDisabled,
                rippleTrigger: rippleTrigger,
                rippleDelay: ripple.delay,
                rippleIntensity: ripple.intensity,
                rippleRotation: ripple.rotation
              ) {
                handleDayTap(dayData.date)
              }
            } else {
              Color.clear.frame(width: layout.dotSize, height: layout.dotSize)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal)
  }

  private func rippleOriginIndex() -> Int? {
    guard let rippleOriginDate else { return nil }
    let originDay = LocalDayCalendar.startOfDay(for: rippleOriginDate)
    return days.firstIndex {
      LocalDayCalendar.startOfDay(for: $0.date) == originDay
    }
  }
}

private struct CalendarGridLayout {
  let dotSize: CGFloat = 10
  let columns: Int
  let rows: Int
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  let hitSize: CGFloat

  init(size: CGSize, dayCount: Int) {
    let padding: CGFloat = 20
    let availableWidth = max(0, size.width - (padding * 2))
    let availableHeight = max(1, size.height - (padding * 2))
    let aspectRatio = max(0.001, availableWidth / availableHeight)
    let targetColumns = Int(sqrt(Double(dayCount) * aspectRatio))
    columns = max(min(targetColumns, dayCount), 1)
    rows = max(Int(ceil(Double(dayCount) / Double(columns))), 1)
    horizontalSpacing = max(0, (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
    verticalSpacing = max(0, (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
    hitSize = dotSize + max(0, min(horizontalSpacing, verticalSpacing))
  }

  func index(row: Int, column: Int) -> Int {
    row * columns + column
  }
}

private struct CalendarGridRipple {
  let delay: Double
  let intensity: Double
  let rotation: Double

  init(index: Int, originIndex: Int?, columns: Int) {
    guard let originIndex else {
      delay = 0
      intensity = 1
      rotation = Self.rotation(for: index)
      return
    }

    let distance = Self.distance(index: index, originIndex: originIndex, columns: columns)
    delay = (distance * 0.038) + ((sin(Double(index) * 12.9898) + 1) * 0.024)
    intensity = max(0.28, 1 - (distance * 0.075))
    rotation = Self.rotation(for: index)
  }

  private static func distance(index: Int, originIndex: Int, columns: Int) -> Double {
    let row = index / columns
    let column = index % columns
    let originRow = originIndex / columns
    let originColumn = originIndex % columns
    return hypot(Double(row - originRow), Double(column - originColumn))
  }

  private static func rotation(for index: Int) -> Double {
    sin(Double(index) * 78.233) >= 0 ? 7 : -7
  }
}

private struct TappableGridDot: View {
  @Environment(\.colorScheme) private var colorScheme

  let color: Color
  let colorSaturation: CGFloat
  let dotSize: CGFloat
  let hitSize: CGFloat
  let isDisabled: Bool
  let rippleTrigger: Int
  let rippleDelay: Double
  let rippleIntensity: Double
  let rippleRotation: Double
  let onTap: () -> Void
  @State private var ripplePhase: Double = 0

  var body: some View {
    let isHighlighting = ripplePhase > 0
    let isRecoiling = ripplePhase < 0
    let lightMix = colorScheme == .dark ? 0.18 : 0.28
    let darkMix = recoilDarkMix(colorSaturation: colorSaturation)
    let highlightForce = ripplePhase * rippleIntensity
    let recoilForce = abs(ripplePhase) * rippleIntensity
    let shimmerColor =
      isHighlighting
      ? color.mix(with: .white, by: lightMix * highlightForce)
      : color.mix(with: .black, by: darkMix * recoilForce)

    GridDot(color: shimmerColor, dotSize: dotSize)
      .frame(width: dotSize, height: dotSize)
      .scaleEffect(isHighlighting ? 1 + (0.24 * highlightForce) : (isRecoiling ? 1 - (0.1 * recoilForce) : 1))
      .rotationEffect(
        .degrees(
          isHighlighting ? rippleRotation * highlightForce : (isRecoiling ? -rippleRotation * 0.5 * recoilForce : 0)
        )
      )
      .saturation(isHighlighting ? 1 + (0.1 * highlightForce) : 1)
      .brightness(
        isHighlighting
          ? 0.04 * highlightForce : (isRecoiling ? recoilBrightness(colorSaturation: colorSaturation) * recoilForce : 0)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(isHighlighting ? (colorScheme == .dark ? 0.2 : 0.28) * highlightForce : 0),
                Color.white.opacity(isHighlighting ? (colorScheme == .dark ? 0.06 : 0.08) * highlightForce : 0),
                Color.clear
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .fill(
            Color.black.opacity(isRecoiling ? recoilOverlayOpacity(colorSaturation: colorSaturation) * recoilForce : 0))
      }
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(Color.white.opacity(isHighlighting ? 0.18 * highlightForce : 0), lineWidth: 1)
          .scaleEffect(isHighlighting ? 1 + (0.24 * highlightForce) : 1)
      }
      .background(
        Color.clear
          .frame(width: hitSize, height: hitSize)
          .contentShape(Rectangle())
          .onTapGesture {
            guard !isDisabled else { return }
            onTap()
          }
      )
      .task(id: rippleTrigger) {
        guard rippleTrigger > 0 else { return }
        await startRipple()
      }
  }

  @MainActor
  private func startRipple() async {
    let delay = UInt64(rippleDelay * 1_000_000_000)
    do {
      try await Task.sleep(nanoseconds: delay)
    } catch {
      return
    }
    withAnimation(.interpolatingSpring(stiffness: 230, damping: 10)) {
      ripplePhase = 1
    }
    do {
      try await Task.sleep(nanoseconds: 210_000_000)
    } catch {
      return
    }
    withAnimation(.interpolatingSpring(stiffness: 190, damping: 11)) {
      ripplePhase = -1
    }
    do {
      try await Task.sleep(nanoseconds: 180_000_000)
    } catch {
      return
    }
    withAnimation(.interpolatingSpring(stiffness: 160, damping: 14)) {
      ripplePhase = 0
    }
  }

  private func recoilDarkMix(colorSaturation: CGFloat) -> Double {
    let isColoredDot = colorSaturation > 0.18
    if colorScheme == .dark {
      return isColoredDot ? 0.3 : 0.14
    }
    return isColoredDot ? 0.18 : 0.045
  }

  private func recoilBrightness(colorSaturation: CGFloat) -> Double {
    let isColoredDot = colorSaturation > 0.18
    if colorScheme == .dark {
      return isColoredDot ? -0.07 : -0.025
    }
    return isColoredDot ? -0.045 : -0.01
  }

  private func recoilOverlayOpacity(colorSaturation: CGFloat) -> Double {
    let isColoredDot = colorSaturation > 0.18
    if colorScheme == .dark {
      return isColoredDot ? 0.1 : 0.025
    }
    return isColoredDot ? 0.055 : 0.008
  }
}
