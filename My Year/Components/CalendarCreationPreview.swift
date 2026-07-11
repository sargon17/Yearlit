import SwiftUI

struct CalendarCreationPreview: View {
  let color: Color
  let completedDays: Set<Int>

  var body: some View {
    Canvas { context, size in
      let columns = 53
      let rows = 7
      let spacing: CGFloat = 2
      let dotSize = min(
        (size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns),
        (size.height - CGFloat(rows - 1) * spacing) / CGFloat(rows)
      )

      for day in 0..<366 {
        let column = day / rows
        let row = day % rows
        let rect = CGRect(
          x: CGFloat(column) * (dotSize + spacing),
          y: CGFloat(row) * (dotSize + spacing),
          width: dotSize,
          height: dotSize
        )
        context.fill(
          Path(roundedRect: rect, cornerRadius: dotSize / 3),
          with: .color(completedDays.contains(day) ? color : .white.opacity(0.1))
        )
      }
    }
    .frame(height: 48)
    .padding(12)
    .lcdScreenEffect(clipShape: RoundedRectangle(cornerRadius: 6), diffusion: 0.12, dotOpacity: 0.42)
    .sameLevelBorder(radius: 6, color: .black)
    .outerSameLevelShadow(radius: 6)
    .accessibilityHidden(true)
  }
}
