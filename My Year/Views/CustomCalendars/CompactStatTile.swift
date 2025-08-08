import SharedModels
import SwiftUI

struct CompactStatTile: View {
  let title: String
  let value: String
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  let accentColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {

      Text(title)
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(Color.textSecondary)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)

      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(value)
          .font(.system(size: 48, design: .monospaced))
          .fontWeight(.black)
          .foregroundColor(accentColor)
          .minimumScaleFactor(0.5)
          .lineLimit(1)

        if let unit = unit {
          Text(unit == .currency ? (currencySymbol ?? "$") : unit.rawValue)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(Color.textTertiary)
            .padding(.bottom, 12)
        }

        Spacer()
      }.frame(maxWidth: .greatestFiniteMagnitude)

    }
  }
}

#Preview {
  CompactStatTile(
    title: "Today's Log",
    value: "12",
    unit: nil,
    currencySymbol: nil,
    accentColor: .green
  )
}
