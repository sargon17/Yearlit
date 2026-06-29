import SwiftUI

struct CalendarGridLayout {
  static let dotSize: CGFloat = 10

  let columns: Int
  let rows: Int
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  let hitSize: CGFloat
  private let origin: CGPoint

  init(size: CGSize, dayCount: Int) {
    let edgeInset: CGFloat = 16
    let availableWidth = max(0, size.width - (edgeInset * 2))
    let availableHeight = max(1, size.height - (edgeInset * 2))
    let aspectRatio = max(0.001, availableWidth / availableHeight)
    let targetColumns = Int(sqrt(Double(dayCount) * aspectRatio))
    columns = max(min(targetColumns, dayCount), 1)
    rows = max(Int(ceil(Double(dayCount) / Double(columns))), 1)
    horizontalSpacing =
      max(0, (availableWidth - (Self.dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
    verticalSpacing =
      max(0, (availableHeight - (Self.dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
    let comfortableHitSize = Self.dotSize * 2.4
    hitSize = max(
      Self.dotSize,
      min(comfortableHitSize, Self.dotSize + max(0, min(horizontalSpacing, verticalSpacing)))
    )
    origin = CGPoint(x: edgeInset + (Self.dotSize / 2), y: edgeInset + (Self.dotSize / 2))
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
