import SwiftUI

struct FeatureStatusBadge: View {
  var label: String
  var color: String?

  private var badgeColor: Color {
    guard let color, !color.isEmpty else { return .red }
    if let hexColor = Color(hex: color) {
      return hexColor
    }
    if let uiColor = UIColor(named: color) {
      return Color(uiColor)
    }
    return .red
  }

  var body: some View {
    VStack {
      HStack(spacing: 6) {
        Circle()
          .foregroundColor(badgeColor)
          .frame(width: 8, height: 8)
        Text(label).font(.system(size: 9))
          .foregroundColor(.textSecondary)
      }
      .padding(.leading, 4)
      .padding(.trailing, 6)
      .padding(.vertical, 2)
    }
    .background(.surfaceMuted)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
          .black.opacity(0.1)
        )
        .cornerRadius(8)
    }
}
