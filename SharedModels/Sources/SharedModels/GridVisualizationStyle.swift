import Foundation
import SwiftUI

/// One day cell, ready for grid rendering.
public struct GridDay: Sendable {
    public let date: Date
    public let color: Color
    /// Normalized 0...1 intensity for the day (entry count vs target/typical volume).
    public let fillRatio: Double

    public init(date: Date, color: Color, fillRatio: Double) {
        self.date = date
        self.color = color
        self.fillRatio = fillRatio
    }
}

/// App-wide style for the year grid marks. Add a case here to introduce a new visualization.
public enum GridVisualizationStyle: String, CaseIterable, Identifiable, Sendable {
    case dot
    case scaledDot
    case sparkle
    case cross

    /// Storage key, shared through the app-group defaults so widgets read the same value.
    public static let preferenceKey = "gridVisualizationStyle"

    /// Reads the style selected in the app. Widgets and one-shot renderers use this.
    public static func stored(
        defaults: UserDefaults = TimelinePreferenceStore.appGroupDefaults
    ) -> GridVisualizationStyle {
        guard let rawValue = defaults.string(forKey: preferenceKey) else { return .dot }
        return GridVisualizationStyle(rawValue: rawValue) ?? .dot
    }

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dot: return String(localized: "Dots")
        case .scaledDot: return String(localized: "Scaled Dots")
        case .sparkle: return String(localized: "Sparkles")
        case .cross: return String(localized: "Crosses")
        }
    }

    /// Side of the mark's bounding square for a given base dot size.
    /// Layout and hit-testing keep using the base size; only the drawn mark changes.
    public func markSize(base: CGFloat, fillRatio: Double) -> CGFloat {
        switch self {
        case .dot:
            return base
        case .scaledDot:
            // sqrt maps value to area instead of diameter, so days near the average
            // stay clearly visible next to outlier days instead of vanishing.
            return base * (0.45 + (0.75 * sqrt(fillRatio)))
        case .sparkle, .cross:
            // Thin shapes need a bigger bounding box to match the dot's visual weight.
            return base * 1.3
        }
    }

    public func path(in rect: CGRect) -> Path {
        switch self {
        case .dot, .scaledDot:
            return Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.3)
        case .sparkle:
            return Self.sparklePath(in: rect)
        case .cross:
            return Self.crossPath(in: rect)
        }
    }

    /// Four-point star with concave sides.
    private static func sparklePath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        // 0 = needle-thin, 1 = straight-sided diamond.
        let waist: CGFloat = 0.3

        let top = CGPoint(x: center.x, y: center.y - radius)
        let right = CGPoint(x: center.x + radius, y: center.y)
        let bottom = CGPoint(x: center.x, y: center.y + radius)
        let left = CGPoint(x: center.x - radius, y: center.y)

        func control(dx: CGFloat, dy: CGFloat) -> CGPoint {
            CGPoint(x: center.x + (dx * radius * waist), y: center.y + (dy * radius * waist))
        }

        var path = Path()
        path.move(to: top)
        path.addQuadCurve(to: right, control: control(dx: 1, dy: -1))
        path.addQuadCurve(to: bottom, control: control(dx: 1, dy: 1))
        path.addQuadCurve(to: left, control: control(dx: -1, dy: 1))
        path.addQuadCurve(to: top, control: control(dx: -1, dy: -1))
        path.closeSubpath()
        return path
    }

    /// Plus sign made of two crossed rounded bars.
    private static func crossPath(in rect: CGRect) -> Path {
        let armWidth = min(rect.width, rect.height) * 0.34
        let corner = CGSize(width: armWidth * 0.35, height: armWidth * 0.35)

        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.midX - (armWidth / 2), y: rect.minY, width: armWidth, height: rect.height),
            cornerSize: corner
        )
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.midY - (armWidth / 2), width: rect.width, height: armWidth),
            cornerSize: corner
        )
        return path
    }
}

/// Draws a style's mark centered in the view frame.
/// For fixed-frame grids (widgets, share cards); the canvas grids compute the mark rect themselves.
public struct GridMarkShape: Shape {
    let style: GridVisualizationStyle
    let fillRatio: Double

    public init(style: GridVisualizationStyle, fillRatio: Double) {
        self.style = style
        self.fillRatio = fillRatio
    }

    public func path(in rect: CGRect) -> Path {
        let side = style.markSize(base: min(rect.width, rect.height), fillRatio: fillRatio)
        let markRect = CGRect(
            x: rect.midX - (side / 2),
            y: rect.midY - (side / 2),
            width: side,
            height: side
        )
        return style.path(in: markRect)
    }
}
