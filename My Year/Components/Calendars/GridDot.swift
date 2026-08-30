import SharedModels
import SwiftUI

struct GridDot: View {
    let color: Color
    let dotSize: CGFloat
    var style: GridVisualizationStyle = .dot
    var fillRatio: Double = 0

    var body: some View {
        GridMarkShape(style: style, fillRatio: fillRatio)
            .fill(color)
            .frame(width: dotSize, height: dotSize)
    }
}
