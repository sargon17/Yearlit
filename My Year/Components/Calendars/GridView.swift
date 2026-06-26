import SharedModels
import SwiftUI
import UIKit

struct GridView: View {
  @Environment(\.colorScheme) private var colorScheme

  let handleDayTap: (Date) -> Void
  let mappedDays: [(date: Date, color: Color)]
  let disabledDates: Set<Date>
  let rippleOriginDate: Date?
  let rippleTrigger: Int
  @State private var rippleStartDate: Date?

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
      let layout = CalendarGridLayout(size: geometry.size, dayCount: mappedDays.count)
      renderedGrid(layout: layout)
    }
    .onChange(of: rippleTrigger) { _, newValue in
      guard newValue > 0 else { return }
      rippleStartDate = Date()
    }
    .task(id: rippleStartDate) {
      guard rippleStartDate != nil else { return }
      do {
        try await Task.sleep(nanoseconds: 1_600_000_000)
      } catch {
        return
      }
      rippleStartDate = nil
    }
  }

  private func renderedGrid(layout: CalendarGridLayout) -> some View {
    let rippleOriginIndex = rippleOriginIndex()

    return Group {
      if rippleStartDate == nil {
        gridCanvas(layout: layout, rippleOriginIndex: rippleOriginIndex, timelineDate: nil)
      } else {
        TimelineView(.animation) { timeline in
          gridCanvas(layout: layout, rippleOriginIndex: rippleOriginIndex, timelineDate: timeline.date)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal)
  }

  private func gridCanvas(
    layout: CalendarGridLayout,
    rippleOriginIndex: Int?,
    timelineDate: Date?
  ) -> some View {
    Canvas { context, _ in
      for index in mappedDays.indices {
        let day = mappedDays[index]
        let ripple = CalendarGridRipple(index: index, originIndex: rippleOriginIndex, columns: layout.columns)
        let phase = timelineDate.map { ripplePhase(for: ripple, at: $0) } ?? 0
        drawDot(
          context: &context,
          color: day.color,
          center: layout.center(for: index),
          ripple: ripple,
          phase: phase
        )
      }
    }
    .contentShape(Rectangle())
    .gesture(
      SpatialTapGesture()
        .onEnded { value in
          guard let index = layout.index(nearest: value.location), mappedDays.indices.contains(index) else { return }
          let day = mappedDays[index]
          guard !disabledDates.contains(day.date) else { return }
          handleDayTap(day.date)
        }
    )
  }

  private func ripplePhase(for ripple: CalendarGridRipple, at date: Date) -> Double {
    guard let rippleStartDate else { return 0 }
    let elapsed = date.timeIntervalSince(rippleStartDate) - ripple.delay
    guard elapsed >= 0 else { return 0 }
    if elapsed < 0.21 {
      return easeOutSpringLike(elapsed / 0.21)
    }
    if elapsed < 0.39 {
      return -easeOutSpringLike((elapsed - 0.21) / 0.18)
    }
    if elapsed < 0.54 {
      return -1 + easeOutSpringLike((elapsed - 0.39) / 0.15)
    }
    return 0
  }

  private func easeOutSpringLike(_ progress: Double) -> Double {
    let clamped = min(1, max(0, progress))
    return 1 - pow(1 - clamped, 3)
  }

  private func drawDot(
    context: inout GraphicsContext,
    color baseColor: Color,
    center: CGPoint,
    ripple: CalendarGridRipple,
    phase: Double
  ) {
    guard phase != 0 else {
      let rect = CGRect(
        x: center.x - (CalendarGridLayout.dotSize / 2),
        y: center.y - (CalendarGridLayout.dotSize / 2),
        width: CalendarGridLayout.dotSize,
        height: CalendarGridLayout.dotSize
      )
      context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(baseColor))
      return
    }

    let isHighlighting = phase > 0
    let isRecoiling = phase < 0
    let highlightForce = phase * ripple.intensity
    let recoilForce = abs(phase) * ripple.intensity
    let lightMix = colorScheme == .dark ? 0.18 : 0.28
    let colorSaturation = saturation(for: baseColor)
    let darkMix = recoilDarkMix(colorSaturation: colorSaturation)
    let color =
      isHighlighting
      ? baseColor.mix(with: Color.white, by: lightMix * highlightForce)
      : baseColor.mix(with: Color.black, by: darkMix * recoilForce)
    let scale = isHighlighting ? 1 + (0.24 * highlightForce) : (isRecoiling ? 1 - (0.1 * recoilForce) : 1)
    let rotation =
      isHighlighting
      ? ripple.rotation * highlightForce
      : (isRecoiling ? -ripple.rotation * 0.5 * recoilForce : 0)

    context.drawLayer { layer in
      layer.translateBy(x: center.x, y: center.y)
      layer.rotate(by: .degrees(rotation))
      layer.scaleBy(x: scale, y: scale)

      let rect = CGRect(
        x: -CalendarGridLayout.dotSize / 2,
        y: -CalendarGridLayout.dotSize / 2,
        width: CalendarGridLayout.dotSize,
        height: CalendarGridLayout.dotSize
      )
      let path = Path(roundedRect: rect, cornerRadius: 3)
      layer.fill(path, with: .color(color))

      if isHighlighting {
        let gradient = Gradient(colors: [
          Color.white.opacity((colorScheme == .dark ? 0.2 : 0.28) * highlightForce),
          Color.white.opacity((colorScheme == .dark ? 0.06 : 0.08) * highlightForce),
          .clear
        ])
        layer.fill(
          path,
          with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
          )
        )
        layer.stroke(path, with: .color(Color.white.opacity(0.18 * highlightForce)), lineWidth: 1)
      }

      if isRecoiling {
        let opacity = recoilOverlayOpacity(colorSaturation: colorSaturation) * recoilForce
        layer.fill(path, with: .color(Color.black.opacity(opacity)))
      }
    }
  }

  private func rippleOriginIndex() -> Int? {
    guard let rippleOriginDate else { return nil }
    let originDay = LocalDayCalendar.startOfDay(for: rippleOriginDate)
    return mappedDays.firstIndex {
      LocalDayCalendar.startOfDay(for: $0.date) == originDay
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

  private func recoilOverlayOpacity(colorSaturation: CGFloat) -> Double {
    let isColoredDot = colorSaturation > 0.18
    if colorScheme == .dark {
      return isColoredDot ? 0.1 : 0.025
    }
    return isColoredDot ? 0.055 : 0.008
  }
}

private struct CalendarGridLayout {
  static let dotSize: CGFloat = 10

  let columns: Int
  let rows: Int
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  let hitSize: CGFloat
  private let origin: CGPoint

  init(size: CGSize, dayCount: Int) {
    let padding: CGFloat = 20
    let availableWidth = max(0, size.width - (padding * 2))
    let availableHeight = max(1, size.height - (padding * 2))
    let aspectRatio = max(0.001, availableWidth / availableHeight)
    let targetColumns = Int(sqrt(Double(dayCount) * aspectRatio))
    columns = max(min(targetColumns, dayCount), 1)
    rows = max(Int(ceil(Double(dayCount) / Double(columns))), 1)
    horizontalSpacing =
      max(0, (availableWidth - (Self.dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
    verticalSpacing =
      max(0, (availableHeight - (Self.dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
    hitSize = Self.dotSize + max(0, min(horizontalSpacing, verticalSpacing))
    origin = CGPoint(x: padding + (Self.dotSize / 2), y: padding + (Self.dotSize / 2))
  }

  func center(for index: Int) -> CGPoint {
    let row = index / columns
    let column = index % columns
    return CGPoint(
      x: origin.x + (CGFloat(column) * (Self.dotSize + horizontalSpacing)),
      y: origin.y + (CGFloat(row) * (Self.dotSize + verticalSpacing))
    )
  }

  func index(nearest point: CGPoint) -> Int? {
    let stepX = Self.dotSize + horizontalSpacing
    let stepY = Self.dotSize + verticalSpacing
    guard stepX > 0, stepY > 0 else { return nil }

    let column = Int(round((point.x - origin.x) / stepX))
    let row = Int(round((point.y - origin.y) / stepY))
    guard row >= 0, row < rows, column >= 0, column < columns else { return nil }

    let index = (row * columns) + column
    let center = center(for: index)
    guard abs(point.x - center.x) <= hitSize / 2, abs(point.y - center.y) <= hitSize / 2 else { return nil }
    return index
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
