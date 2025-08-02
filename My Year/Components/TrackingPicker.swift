import SharedModels
import SwiftUI

struct TrackingPicker: View {
  @Binding var trackingType: TrackingType

  var body: some View {
    CustomSection(label: "Tracking Type") {

      HStack(spacing: 2) {
        ForEach(TrackingType.allCases, id: \.self) { type in
          Button {
            withAnimation(.snappy) {
              trackingType = type
            }
            Task {
              await hepticFeedback(option: .rigid)
            }
          } label: {
            VStack {
              Image(systemName: type.icon)
                .font(.system(size: 16))
                .foregroundStyle(
                  trackingType == type
                    ? .orange
                    : .textTertiary
                )
              Text(type.label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(
                  trackingType == type ? .orange : .textTertiary.opacity(0.5)
                )
            }
            .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
            .aspectRatio(2.5, contentMode: .fit)
          }
          .padding()
          .sameLevelBorder()

        }
      }
      .padding(.all, 2)
      .frame(maxWidth: .greatestFiniteMagnitude)
      .background(getVoidColor())
      .cornerRadius(6)
      .outerSameLevelShadow(radius: 6)
    }
  }
}
