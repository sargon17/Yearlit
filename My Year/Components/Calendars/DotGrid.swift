import SwiftUI

struct DotGridLayout: Equatable {
  let columns: Int
  let rows: Int
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  let hitSize: CGFloat

  init(itemCount: Int, size: CGSize, dotSize: CGFloat, padding: CGFloat) {
    let safeItemCount = max(itemCount, 1)
    let availableWidth = max(0, size.width - (padding * 2))
    let availableHeight = max(1, size.height - (padding * 2))
    let aspectRatio = max(0.001, availableWidth / availableHeight)
    let targetColumns = Int(sqrt(Double(safeItemCount) * aspectRatio))

    columns = max(min(targetColumns, safeItemCount), 1)
    rows = max(Int(ceil(Double(safeItemCount) / Double(columns))), 1)
    horizontalSpacing = max(0, (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(1, columns - 1)))
    verticalSpacing = max(0, (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(1, rows - 1)))
    hitSize = dotSize + max(0, min(horizontalSpacing, verticalSpacing))
  }
}

struct DotGrid<Item, Dot: View>: View {
  let items: [Item]
  let dotSize: CGFloat
  let padding: CGFloat
  let dot: (Item) -> Dot
  let onTap: ((Item) -> Void)?

  var body: some View {
    GeometryReader { geometry in
      let layout = DotGridLayout(
        itemCount: items.count,
        size: geometry.size,
        dotSize: dotSize,
        padding: padding
      )

      VStack(spacing: layout.verticalSpacing) {
        ForEach(0..<layout.rows, id: \.self) { row in
          HStack(spacing: layout.horizontalSpacing) {
            ForEach(0..<layout.columns, id: \.self) { col in
              let index = row * layout.columns + col
              if index < items.count {
                let item = items[index]
                cell(for: item, layout: layout)
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

  @ViewBuilder
  private func cell(for item: Item, layout: DotGridLayout) -> some View {
    let base = dot(item)
      .frame(width: dotSize, height: dotSize)

    if let onTap {
      base.background(
        Color.clear
          .frame(width: layout.hitSize, height: layout.hitSize)
          .contentShape(Rectangle())
          .onTapGesture {
            onTap(item)
          }
      )
    } else {
      base
    }
  }
}
