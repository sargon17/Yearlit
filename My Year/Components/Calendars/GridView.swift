import SharedModels
import SwiftUI

struct GridView: View {
  let handleDayTap: (Date) -> Void
  let mappedDays: [(date: Date, color: Color)]
  let disabledDates: Set<Date>

  init(
    handleDayTap: @escaping (Date) -> Void,
    mappedDays: [(date: Date, color: Color)],
    disabledDates: Set<Date>
  ) {
    self.handleDayTap = handleDayTap
    self.mappedDays = mappedDays
    self.disabledDates = disabledDates
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
                  isDisabled: disabledDates.contains(mappedDay.date)
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
}

private struct TappableGridDot: View {
  let color: Color
  let dotSize: CGFloat
  let hitSize: CGFloat
  let isDisabled: Bool
  let onTap: () -> Void

  var body: some View {
    GridDot(color: color, dotSize: dotSize)
      .frame(width: dotSize, height: dotSize)
      .background(
        Color.clear
          .frame(width: hitSize, height: hitSize)
          .contentShape(Rectangle())
          .onTapGesture {
            guard !isDisabled else { return }
            onTap()
          }
      )
  }
}
