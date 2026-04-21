import SharedModels
import SwiftUI

struct TrackingPicker: View {
    @Binding var trackingType: TrackingType
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    private func trackingTypeLabel(for type: TrackingType) -> LocalizedStringKey {
        switch type {
        case .binary:
            return "Binary"
        case .counter:
            return "Counter"
        case .multipleDaily:
            return "Target"
        }
    }

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
                                title: trackingTypeLabel(for: type),
                                accentColor: color,
                                isSelected: trackingType == type
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(trackingTypeLabel(for: type)))
                }
            }
            .padding(.all, 2)
            .frame(maxWidth: .greatestFiniteMagnitude)
            .background(getVoidColor(colorScheme: colorScheme))
        }
    }
}
