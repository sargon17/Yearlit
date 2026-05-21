import SwiftUI

struct UnionOneShape: Shape {
  func path(in rect: CGRect) -> Path {
    let sourceSize: CGFloat = 92
    let scale = min(rect.width, rect.height) / sourceSize
    let offset = CGPoint(
      x: rect.midX - sourceSize * scale / 2,
      y: rect.midY - sourceSize * scale / 2
    )

    return Self.sourcePath.applying(
      CGAffineTransform(translationX: offset.x, y: offset.y)
        .scaledBy(x: scale, y: scale)
    )
  }

  private static let sourcePath: Path = {
    var path = Path()
    path.move(to: CGPoint(x: 20, y: 80.5))
    path.addCurve(
      to: CGPoint(x: 23, y: 77.5), control1: CGPoint(x: 21.6569, y: 80.5), control2: CGPoint(x: 23, y: 79.1569))
    path.addLine(to: CGPoint(x: 23, y: 60.5))
    path.addCurve(
      to: CGPoint(x: 20, y: 57.5), control1: CGPoint(x: 23, y: 58.8431), control2: CGPoint(x: 21.6569, y: 57.5))
    path.addLine(to: CGPoint(x: 14.5, y: 57.5))
    path.addCurve(
      to: CGPoint(x: 11.5, y: 60.5), control1: CGPoint(x: 12.8431, y: 57.5), control2: CGPoint(x: 11.5, y: 58.8431))
    path.addLine(to: CGPoint(x: 11.5, y: 66))
    path.addCurve(
      to: CGPoint(x: 8.5, y: 69), control1: CGPoint(x: 11.5, y: 67.6569), control2: CGPoint(x: 10.1569, y: 69))
    path.addLine(to: CGPoint(x: 3, y: 69))
    path.addCurve(to: CGPoint(x: 0, y: 66), control1: CGPoint(x: 1.34314, y: 69), control2: CGPoint(x: 0, y: 67.6569))
    path.addLine(to: CGPoint(x: 0, y: 49))
    path.addCurve(to: CGPoint(x: 3, y: 46), control1: CGPoint(x: 0, y: 47.3431), control2: CGPoint(x: 1.34314, y: 46))
    path.addLine(to: CGPoint(x: 8.5, y: 46))
    path.addCurve(
      to: CGPoint(x: 11.5, y: 43), control1: CGPoint(x: 10.1569, y: 46), control2: CGPoint(x: 11.5, y: 44.6569))
    path.addLine(to: CGPoint(x: 11.5, y: 14.5))
    path.addCurve(
      to: CGPoint(x: 8.5, y: 11.5), control1: CGPoint(x: 11.5, y: 12.8431), control2: CGPoint(x: 10.1569, y: 11.5))
    path.addLine(to: CGPoint(x: 3, y: 11.5))
    path.addCurve(
      to: CGPoint(x: 0, y: 8.5), control1: CGPoint(x: 1.34314, y: 11.5), control2: CGPoint(x: 0, y: 10.1569))
    path.addLine(to: CGPoint(x: 0, y: 3))
    path.addCurve(to: CGPoint(x: 3, y: 0), control1: CGPoint(x: 0, y: 1.34315), control2: CGPoint(x: 1.34314, y: 0))
    path.addLine(to: CGPoint(x: 43, y: 0))
    path.addCurve(to: CGPoint(x: 46, y: 3), control1: CGPoint(x: 44.6569, y: 0), control2: CGPoint(x: 46, y: 1.34315))
    path.addLine(to: CGPoint(x: 46, y: 8.5))
    path.addCurve(
      to: CGPoint(x: 49, y: 11.5), control1: CGPoint(x: 46, y: 10.1569), control2: CGPoint(x: 47.3431, y: 11.5))
    path.addLine(to: CGPoint(x: 57.5, y: 11.5))
    path.addLine(to: CGPoint(x: 57.5, y: 20))
    path.addCurve(
      to: CGPoint(x: 54.5, y: 23), control1: CGPoint(x: 57.5, y: 21.6569), control2: CGPoint(x: 56.1568, y: 23))
    path.addLine(to: CGPoint(x: 49, y: 23))
    path.addCurve(to: CGPoint(x: 46, y: 26), control1: CGPoint(x: 47.3431, y: 23), control2: CGPoint(x: 46, y: 24.3431))
    path.addLine(to: CGPoint(x: 46, y: 54.5))
    path.addCurve(
      to: CGPoint(x: 43, y: 57.5), control1: CGPoint(x: 46, y: 56.1569), control2: CGPoint(x: 44.6569, y: 57.5))
    path.addLine(to: CGPoint(x: 37.5, y: 57.5))
    path.addCurve(
      to: CGPoint(x: 34.5, y: 60.5), control1: CGPoint(x: 35.8431, y: 57.5), control2: CGPoint(x: 34.5, y: 58.8431))
    path.addLine(to: CGPoint(x: 34.5, y: 66))
    path.addCurve(
      to: CGPoint(x: 37.5, y: 69), control1: CGPoint(x: 34.5, y: 67.6569), control2: CGPoint(x: 35.8431, y: 69))
    path.addLine(to: CGPoint(x: 57.5, y: 69))
    path.addLine(to: CGPoint(x: 57.5, y: 77.5))
    path.addCurve(
      to: CGPoint(x: 60.5, y: 80.5), control1: CGPoint(x: 57.5, y: 79.1569), control2: CGPoint(x: 58.8431, y: 80.5))
    path.addLine(to: CGPoint(x: 66, y: 80.5))
    path.addCurve(
      to: CGPoint(x: 69, y: 77.5), control1: CGPoint(x: 67.6569, y: 80.5), control2: CGPoint(x: 69, y: 79.1569))
    path.addLine(to: CGPoint(x: 69, y: 72))
    path.addCurve(to: CGPoint(x: 66, y: 69), control1: CGPoint(x: 69, y: 70.3431), control2: CGPoint(x: 67.6569, y: 69))
    path.addLine(to: CGPoint(x: 57.5, y: 69))
    path.addLine(to: CGPoint(x: 57.5, y: 60.5))
    path.addCurve(
      to: CGPoint(x: 60.5, y: 57.5), control1: CGPoint(x: 57.5, y: 58.8431), control2: CGPoint(x: 58.8431, y: 57.5))
    path.addLine(to: CGPoint(x: 66, y: 57.5))
    path.addCurve(
      to: CGPoint(x: 69, y: 54.5), control1: CGPoint(x: 67.6569, y: 57.5), control2: CGPoint(x: 69, y: 56.1568))
    path.addLine(to: CGPoint(x: 69, y: 49))
    path.addCurve(to: CGPoint(x: 66, y: 46), control1: CGPoint(x: 69, y: 47.3431), control2: CGPoint(x: 67.6569, y: 46))
    path.addLine(to: CGPoint(x: 60.5, y: 46))
    path.addCurve(
      to: CGPoint(x: 57.5, y: 43), control1: CGPoint(x: 58.8431, y: 46), control2: CGPoint(x: 57.5, y: 44.6569))
    path.addLine(to: CGPoint(x: 57.5, y: 37.5))
    path.addCurve(
      to: CGPoint(x: 60.5, y: 34.5), control1: CGPoint(x: 57.5, y: 35.8431), control2: CGPoint(x: 58.8431, y: 34.5))
    path.addLine(to: CGPoint(x: 66, y: 34.5))
    path.addCurve(
      to: CGPoint(x: 69, y: 31.5), control1: CGPoint(x: 67.6569, y: 34.5), control2: CGPoint(x: 69, y: 33.1568))
    path.addLine(to: CGPoint(x: 69, y: 26))
    path.addCurve(to: CGPoint(x: 72, y: 23), control1: CGPoint(x: 69, y: 24.3431), control2: CGPoint(x: 70.3431, y: 23))
    path.addLine(to: CGPoint(x: 77.5, y: 23))
    path.addCurve(
      to: CGPoint(x: 80.5, y: 20), control1: CGPoint(x: 79.1568, y: 23), control2: CGPoint(x: 80.5, y: 21.6568))
    path.addLine(to: CGPoint(x: 80.5, y: 14.5))
    path.addCurve(
      to: CGPoint(x: 77.5, y: 11.5), control1: CGPoint(x: 80.5, y: 12.8431), control2: CGPoint(x: 79.1568, y: 11.5))
    path.addLine(to: CGPoint(x: 57.5, y: 11.5))
    path.addLine(to: CGPoint(x: 57.5, y: 3))
    path.addCurve(
      to: CGPoint(x: 60.5, y: 0), control1: CGPoint(x: 57.5, y: 1.34314), control2: CGPoint(x: 58.8431, y: 0))
    path.addLine(to: CGPoint(x: 89, y: 0))
    path.addCurve(to: CGPoint(x: 92, y: 3), control1: CGPoint(x: 90.6568, y: 0), control2: CGPoint(x: 92, y: 1.34314))
    path.addLine(to: CGPoint(x: 92, y: 43))
    path.addCurve(to: CGPoint(x: 89, y: 46), control1: CGPoint(x: 92, y: 44.6569), control2: CGPoint(x: 90.6569, y: 46))
    path.addLine(to: CGPoint(x: 83.5, y: 46))
    path.addCurve(
      to: CGPoint(x: 80.5, y: 49), control1: CGPoint(x: 81.8431, y: 46), control2: CGPoint(x: 80.5, y: 47.3431))
    path.addLine(to: CGPoint(x: 80.5, y: 54.5))
    path.addCurve(
      to: CGPoint(x: 83.5, y: 57.5), control1: CGPoint(x: 80.5, y: 56.1568), control2: CGPoint(x: 81.8431, y: 57.5))
    path.addLine(to: CGPoint(x: 89, y: 57.5))
    path.addCurve(
      to: CGPoint(x: 92, y: 60.5), control1: CGPoint(x: 90.6569, y: 57.5), control2: CGPoint(x: 92, y: 58.8431))
    path.addLine(to: CGPoint(x: 92, y: 77.5))
    path.addCurve(
      to: CGPoint(x: 89, y: 80.5), control1: CGPoint(x: 92, y: 79.1568), control2: CGPoint(x: 90.6569, y: 80.5))
    path.addLine(to: CGPoint(x: 83.5, y: 80.5))
    path.addCurve(
      to: CGPoint(x: 80.5, y: 83.5), control1: CGPoint(x: 81.8431, y: 80.5), control2: CGPoint(x: 80.5, y: 81.8431))
    path.addLine(to: CGPoint(x: 80.5, y: 89))
    path.addCurve(
      to: CGPoint(x: 77.5, y: 92), control1: CGPoint(x: 80.5, y: 90.6569), control2: CGPoint(x: 79.1569, y: 92))
    path.addLine(to: CGPoint(x: 49, y: 92))
    path.addCurve(to: CGPoint(x: 46, y: 89), control1: CGPoint(x: 47.3431, y: 92), control2: CGPoint(x: 46, y: 90.6569))
    path.addLine(to: CGPoint(x: 46, y: 83.5))
    path.addCurve(
      to: CGPoint(x: 43, y: 80.5), control1: CGPoint(x: 46, y: 81.8431), control2: CGPoint(x: 44.6569, y: 80.5))
    path.addLine(to: CGPoint(x: 37.5, y: 80.5))
    path.addCurve(
      to: CGPoint(x: 34.5, y: 83.5), control1: CGPoint(x: 35.8431, y: 80.5), control2: CGPoint(x: 34.5, y: 81.8431))
    path.addLine(to: CGPoint(x: 34.5, y: 89))
    path.addCurve(
      to: CGPoint(x: 31.5, y: 92), control1: CGPoint(x: 34.5, y: 90.6569), control2: CGPoint(x: 33.1569, y: 92))
    path.addLine(to: CGPoint(x: 3, y: 92))
    path.addCurve(to: CGPoint(x: 0, y: 89), control1: CGPoint(x: 1.34315, y: 92), control2: CGPoint(x: 0, y: 90.6569))
    path.addLine(to: CGPoint(x: 0, y: 83.5))
    path.addCurve(
      to: CGPoint(x: 3, y: 80.5), control1: CGPoint(x: 0, y: 81.8431), control2: CGPoint(x: 1.34315, y: 80.5))
    path.closeSubpath()

    path.move(to: CGPoint(x: 31.5, y: 46))
    path.addCurve(
      to: CGPoint(x: 34.5, y: 43), control1: CGPoint(x: 33.1569, y: 46), control2: CGPoint(x: 34.5, y: 44.6569))
    path.addLine(to: CGPoint(x: 34.5, y: 14.5))
    path.addCurve(
      to: CGPoint(x: 31.5, y: 11.5), control1: CGPoint(x: 34.5, y: 12.8431), control2: CGPoint(x: 33.1568, y: 11.5))
    path.addLine(to: CGPoint(x: 26, y: 11.5))
    path.addCurve(
      to: CGPoint(x: 23, y: 14.5), control1: CGPoint(x: 24.3431, y: 11.5), control2: CGPoint(x: 23, y: 12.8431))
    path.addLine(to: CGPoint(x: 23, y: 43))
    path.addCurve(to: CGPoint(x: 26, y: 46), control1: CGPoint(x: 23, y: 44.6569), control2: CGPoint(x: 24.3431, y: 46))
    path.closeSubpath()
    return path
  }()
}
