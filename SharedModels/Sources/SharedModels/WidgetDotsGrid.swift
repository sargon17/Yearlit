import SwiftUI

struct WidgetDotsGrid<Dot: View>: View {
    let count: Int
    let dotSize: CGFloat
    @ViewBuilder let dot: (Int) -> Dot

    var body: some View {
        GeometryReader { geometry in
            let layout = WidgetStyle.gridLayout(
                count: count,
                dotSize: dotSize,
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height
            )

            VStack(spacing: layout.verticalSpacing) {
                ForEach(0 ..< layout.rows, id: \.self) { row in
                    HStack(spacing: layout.horizontalSpacing) {
                        ForEach(0 ..< layout.columns, id: \.self) { column in
                            let index = row * layout.columns + column
                            if index < count {
                                dot(index)
                            } else {
                                Color.clear.frame(width: dotSize, height: dotSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
