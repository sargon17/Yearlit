import SharedModels
import SwiftUI
import UIKit

struct OnboardingFirstDotCalendarGrid: View {
  let calendar: CustomCalendar
  let today: Date
  let completedDates: Set<Date>
  let rippleTrigger: Int
  let allowsPastAndTodayTaps: Bool
  let onDayTapped: (Date) -> Void

  init(
    calendar: CustomCalendar,
    today: Date,
    completedDates: Set<Date>,
    rippleTrigger: Int = 0,
    allowsPastAndTodayTaps: Bool = true,
    onDayTapped: @escaping (Date) -> Void = { _ in }
  ) {
    self.calendar = calendar
    self.today = today
    self.completedDates = completedDates
    self.rippleTrigger = rippleTrigger
    self.allowsPastAndTodayTaps = allowsPastAndTodayTaps
    self.onDayTapped = onDayTapped
  }

  private let columns = 10
  private let dotSize: CGFloat = 58
  private let spacing: CGFloat = 18
  private let dotCornerRadius: CGFloat = 9

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

      ZStack {
        ForEach(0..<(rows * columns), id: \.self) { index in
          let row = index / columns
          let column = index % columns
          let x = (width / 2) + CGFloat(column - centerColumn) * (dotSize + spacing)
          let y = (height / 2) + CGFloat(row - centerRow) * (dotSize + spacing)
          let date = date(for: index, todayIndex: todayIndex)
          let isTappable = allowsPastAndTodayTaps && index <= todayIndex

          OnboardingRippleGridDot(
            color: color(for: date, index: index, todayIndex: todayIndex),
            size: dotSize,
            cornerRadius: dotCornerRadius,
            rippleTrigger: rippleTrigger,
            ripple: CalendarGridRipple(index: index, originIndex: todayIndex, columns: columns),
            isTappable: isTappable
          ) {
            onDayTapped(date)
          }
          .position(x: x, y: y)
          .animation(.easeInOut(duration: 0.28), value: completedDates)
        }
      }
      .rotationEffect(.degrees(11), anchor: .center)
      .scaleEffect(1.08, anchor: .center)
      .ignoresSafeArea(.container, edges: .top)
      .mask(
        Rectangle()
          .padding(.vertical, -height * 0.15)
      )
    }
    .accessibilityHidden(true)
  }

  private func color(for date: Date, index: Int, todayIndex: Int) -> Color {
    let bucketDate = calendar.bucketDate(for: date)
    if completedDates.contains(bucketDate) {
      return Color(calendar.color)
    }

    if index == todayIndex {
      return activeDayColor()
    }

    if index > todayIndex {
      return futureDayColor()
    }

    return missedDayColor()
  }

  private func date(for index: Int, todayIndex: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: index - todayIndex, to: today) ?? today
  }

  private func index(row: Int, column: Int) -> Int {
    (row * columns) + column
  }
}

private struct OnboardingRippleGridDot: View {
  let color: Color
  let size: CGFloat
  let cornerRadius: CGFloat
  let rippleTrigger: Int
  let ripple: CalendarGridRipple
  let isTappable: Bool
  let onTap: () -> Void

  // 1 = highlight, -1 = recoil, 0 = rest. Mirrors GridView's ripple phase envelope.
  @State private var phase: Double = 0

  @Environment(\.colorScheme) private var colorScheme

  private var highlightForce: Double { phase > 0 ? phase * ripple.intensity : 0 }
  private var recoilForce: Double { phase < 0 ? -phase * ripple.intensity : 0 }

  var body: some View {
    Button {
      guard isTappable else { return }
      onTap()
    } label: {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(displayColor)
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(colorScheme == .dark ? 0.2 : 0.28),
                  Color.white.opacity(colorScheme == .dark ? 0.06 : 0.08),
                  .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .opacity(highlightForce)

          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(Color.white.opacity(0.18 * highlightForce), lineWidth: 1)

          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.black.opacity(recoilOverlayOpacity() * recoilForce))
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!isTappable)
    .onChange(of: rippleTrigger) { _, trigger in
      guard trigger > 0 else { return }
      startRipple()
    }
  }

  private var displayColor: Color {
    if phase > 0 {
      return color.mix(with: .white, by: (colorScheme == .dark ? 0.18 : 0.28) * highlightForce)
    }
    if phase < 0 {
      return color.mix(with: .black, by: recoilDarkMix() * recoilForce)
    }
    return color
  }

  private var scale: Double {
    if phase > 0 { return 1 + (0.24 * highlightForce) }
    if phase < 0 { return 1 - (0.1 * recoilForce) }
    return 1
  }

  private var rotation: Double {
    if phase > 0 { return ripple.rotation * highlightForce }
    if phase < 0 { return -ripple.rotation * 0.5 * recoilForce }
    return 0
  }

  // Same timings as GridView.ripplePhase: 0.21s highlight, 0.18s recoil, 0.15s settle.
  private func startRipple() {
    DispatchQueue.main.asyncAfter(deadline: .now() + ripple.delay) {
      withAnimation(.easeOut(duration: 0.21)) {
        phase = 1
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
        withAnimation(.easeOut(duration: 0.18)) {
          phase = -1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
          withAnimation(.easeOut(duration: 0.15)) {
            phase = 0
          }
        }
      }
    }
  }

  private func recoilDarkMix() -> Double {
    let isColoredDot = saturation(of: color) > 0.18
    if colorScheme == .dark {
      return isColoredDot ? 0.3 : 0.14
    }
    return isColoredDot ? 0.18 : 0.045
  }

  private func recoilOverlayOpacity() -> Double {
    let isColoredDot = saturation(of: color) > 0.18
    if colorScheme == .dark {
      return isColoredDot ? 0.1 : 0.025
    }
    return isColoredDot ? 0.055 : 0.008
  }

  private func saturation(of color: Color) -> CGFloat {
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
}
