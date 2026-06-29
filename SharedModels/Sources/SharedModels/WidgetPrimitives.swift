import SwiftUI

public struct WidgetGridDot: View {
    public let color: Color
    public let dotSize: CGFloat
    public let accentable: Bool

    public init(color: Color, dotSize: CGFloat, accentable: Bool = false) {
        self.color = color
        self.dotSize = dotSize
        self.accentable = accentable
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: dotSize, height: dotSize)
            .widgetAccentable(accentable)
    }
}

public struct WidgetSeparator: View {
    public let renderingMode: WidgetStyle.RenderingMode

    public init(renderingMode: WidgetStyle.RenderingMode = .fullColor) {
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(WidgetStyle.separatorTopColor(renderingMode: renderingMode))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(WidgetStyle.separatorBottomColor(renderingMode: renderingMode))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .widgetAccentable(false)
    }
}
