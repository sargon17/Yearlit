import SharedModels
import SwiftUI

struct TrackingPicker: View {
    @Binding var trackingType: TrackingType
    let color: Color

    var body: some View {
        CustomSection(label: "Tracking Type") {
            HStack(spacing: 2) {
                ForEach(TrackingType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.snappy) {
                            trackingType = type
                        }
                        Task {
                            await hapticFeedback(.rigid)
                        }
                    } label: {
                        PickerOptionTile(isSelected: trackingType == type, isEnabled: true) {
                            PickerOptionContent(
                                icon: type.icon,
                                title: type.displayTitle,
                                accentColor: color,
                                isSelected: trackingType == type
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(type.displayTitle))
                }
            }
            .padding(.all, 2)
            .frame(maxWidth: .greatestFiniteMagnitude)
            .sameLevelGroupBackground()
        }
    }
}
