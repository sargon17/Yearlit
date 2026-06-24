import SharedModels
import SwiftUI
import UIKit

struct GridView: View {
  let handleDayTap: (Date) -> Void
  let mappedDays: [(date: Date, color: Color)]
  let disabledDates: Set<Date>
  let rippleOriginDate: Date?
  let rippleTrigger: Int

  init(
    handleDayTap: @escaping (Date) -> Void,
    mappedDays: [(date: Date, color: Color)],
    disabledDates: Set<Date>,
    rippleOriginDate: Date? = nil,
    rippleTrigger: Int = 0
  ) {
    self.handleDayTap = handleDayTap
    self.mappedDays = mappedDays
    self.disabledDates = disabledDates
    self.rippleOriginDate = rippleOriginDate
    self.rippleTrigger = rippleTrigger
  }

  var body: some View {
    GeometryReader { geometry in
      let dotSize: CGFloat = 10
      let padding: CGFloat = 20

      let availableWidth = max(0, geometry.size.width - (padding * 2))
      let availableHeight = max(1, geometry.size.height - (padding * 2))

      let dayCount = mappedDays.count
      let aspectRatio = max(0.001, availableWidth / availableHeight)
      let targetColumns = Int(sqrt(Double(dayCount) * aspectRatio))
      let columns = max(min(targetColumns, dayCount), 1)
      let rows = max(Int(ceil(Double(dayCount) / Double(columns))), 1)

      let horizontalSpacing =
        max(0, (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
      let verticalSpacing =
        max(0, (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
      let hitSize = dotSize + max(0, min(horizontalSpacing, verticalSpacing))
      let rippleOriginIndex = rippleOriginIndex()

      VStack(spacing: verticalSpacing) {
        ForEach(0..<rows, id: \.self) { row in
          HStack(spacing: horizontalSpacing) {
            ForEach(0..<columns, id: \.self) { col in
              let day = row * columns + col
              if day < mappedDays.count {
                let mappedDay = mappedDays[day]

                TappableGridDot(
                  color: mappedDay.color,
                  dotSize: dotSize,
                  hitSize: hitSize,
                  isDisabled: disabledDates.contains(mappedDay.date),
                  rippleTrigger: rippleTrigger,
                  rippleDelay: rippleDelay(
                    for: day,
                    originIndex: rippleOriginIndex,
                    columns: columns
                  ),
                  rippleIntensity: rippleIntensity(
                    for: day,
                    originIndex: rippleOriginIndex,
                    columns: columns
                  ),
                  rippleRotation: rippleRotation(for: day)
                ) {
                  handleDayTap(mappedDay.date)
                }
              } else {
                Color.clear.frame(width: dotSize, height: dotSize)
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.horizontal)
    }
  }

  private func rippleOriginIndex() -> Int? {
    guard let rippleOriginDate else { return nil }
    let originDay = LocalDayCalendar.startOfDay(for: rippleOriginDate)
    return mappedDays.firstIndex {
      LocalDayCalendar.startOfDay(for: $0.date) == originDay
    }
  }

  private func rippleDelay(for index: Int, originIndex: Int?, columns: Int) -> Double {
    guard let originIndex else { return 0 }
    let distance = rippleDistance(for: index, originIndex: originIndex, columns: columns)
    let jitter = (sin(Double(index) * 12.9898) + 1) * 0.024
    return (distance * 0.038) + jitter
  }

  private func rippleIntensity(for index: Int, originIndex: Int?, columns: Int) -> Double {
    guard let originIndex else { return 1 }
    let distance = rippleDistance(for: index, originIndex: originIndex, columns: columns)
    return max(0.28, 1 - (distance * 0.075))
  }

  private func rippleDistance(for index: Int, originIndex: Int, columns: Int) -> Double {
    let row = index / columns
    let column = index % columns
    let originRow = originIndex / columns
    let originColumn = originIndex % columns
    return hypot(Double(row - originRow), Double(column - originColumn))
  }

  private func rippleRotation(for index: Int) -> Double {
    sin(Double(index) * 78.233) >= 0 ? 7 : -7
  }
}

private struct TappableGridDot: View {
  @Environment(\.colorScheme) private var colorScheme

  let color: Color
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
    let colorSaturation = saturation(for: color)
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
        isHighlighting ? 0.04 * highlightForce : (isRecoiling ? recoilBrightness(colorSaturation: colorSaturation) * recoilForce : 0)
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
          .fill(Color.black.opacity(isRecoiling ? recoilOverlayOpacity(colorSaturation: colorSaturation) * recoilForce : 0))
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

  private func saturation(for color: Color) -> CGFloat {
    let uiColor = UIColor(color)
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
      return 0
    }
    return saturation
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
