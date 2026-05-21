import SharedModels
import SwiftUI

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
            rippleDelay: rippleDelay(row: row, column: column, centerRow: centerRow, centerColumn: centerColumn),
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

  private func rippleDelay(row: Int, column: Int, centerRow: Int, centerColumn: Int) -> Double {
    let distance = hypot(Double(row - centerRow), Double(column - centerColumn))
    return distance * 0.085
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
  let rippleDelay: Double
  let isTappable: Bool
  let onTap: () -> Void

  @State private var isRippling = false

  var body: some View {
    Button {
      guard isTappable else { return }
      onTap()
    } label: {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(color)
        .frame(width: size, height: size)
        .scaleEffect(isRippling ? 1.16 : 1)
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(Color.brand.opacity(isRippling ? 0.55 : 0), lineWidth: 2)
            .scaleEffect(isRippling ? 1.28 : 1)
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!isTappable)
    .onChange(of: rippleTrigger) { _, trigger in
      guard trigger > 0 else { return }
      startRipple()
    }
  }

  private func startRipple() {
    DispatchQueue.main.asyncAfter(deadline: .now() + rippleDelay) {
      withAnimation(.easeOut(duration: 0.26)) {
        isRippling = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.easeOut(duration: 0.48)) {
          isRippling = false
        }
      }
    }
  }
}
