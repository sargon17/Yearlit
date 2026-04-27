import SharedModels
import SwiftUI
import SwiftfulRouting

enum CompactStatTileSize {
  case small
  case large

  var fontSize: CGFloat {
    switch self {
    case .small:
      return 24
    case .large:
      return 48
    }
  }
}

struct CompactStatTile: View {
  let title: LocalizedStringKey
  let value: String
  let accentColor: Color
  var size: CompactStatTileSize = .large
  var isLocked: Bool = false
  var onTap: (() -> Void)? = nil

  @Environment(\.router) var router

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 10, design: .monospaced))
          .foregroundColor(Color.textSecondary)
          .lineLimit(1)
          .fixedSize(horizontal: false, vertical: true)

        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(verbatim: value)
            .font(.system(size: size.fontSize, design: .monospaced))
            .fontWeight(.black)
            .foregroundColor(accentColor)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .blur(radius: isLocked ? 10 : 0)
        }
      }
      Spacer()
    }
    .frame(maxWidth: .greatestFiniteMagnitude)
    .contentShape(Rectangle())
    .onTapGesture {
      if isLocked {
        router.showScreen(.sheet) { _ in
          EntitlementRefreshingPaywallView()
        }

        Task {
          await hapticFeedback()
        }
      } else {
        onTap?()
      }
    }
  }
}
