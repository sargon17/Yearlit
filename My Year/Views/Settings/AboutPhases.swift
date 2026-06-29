import SwiftUI

enum AboutPhases: CaseIterable, Identifiable, Comparable {
  case presentation
  case yearlit
  case feedback

  var id: Self {
    self
  }
}

struct ElapsedIndicator: View {
  let totalTime: Double
  let elapsedTime: Double

  init(_ totalTime: Double, _ elapsedTime: Double) {
    self.totalTime = totalTime
    self.elapsedTime = elapsedTime
  }

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let elapsedWidth = CGFloat((Double(width) / totalTime) * elapsedTime)

      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 4)
          .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: 4)
          .foregroundStyle(.textTertiary.opacity(0.2))

        RoundedRectangle(cornerRadius: 4)
          .frame(maxWidth: elapsedWidth, maxHeight: 4)
          .foregroundStyle(.surfacePrimary)
      }
      .frame(maxHeight: 4)
    }
  }
}
