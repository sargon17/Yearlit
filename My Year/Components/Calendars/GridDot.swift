import SharedModels
import SwiftUI

struct GridDot: View {
    let color: Color
    let dotSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                color
            )
            .frame(width: dotSize, height: dotSize)
    }
}
