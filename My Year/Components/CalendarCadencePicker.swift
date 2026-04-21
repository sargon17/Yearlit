import SharedModels
import SwiftUI

struct CalendarCadencePicker: View {
    let cadence: CalendarCadence
    let color: Color
    let isEditable: Bool
    let onSelect: (CalendarCadence) -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        CustomSection(label: "Cadence") {
            HStack(spacing: 2) {
                ForEach(CalendarCadence.allCases, id: \.self) { option in
                    cadenceTile(for: option)
                }
            }
            .padding(.all, 2)
            .frame(maxWidth: .greatestFiniteMagnitude)
            .background(getVoidColor(colorScheme: colorScheme))
        }
    }

    @ViewBuilder
    private func cadenceTile(for option: CalendarCadence) -> some View {
        let tile = PickerOptionTile(
            isSelected: cadence == option,
            isEnabled: isEditable
        ) {
            PickerOptionContent(
                icon: option.icon,
                title: LocalizedStringKey(option.title),
                accentColor: color,
                isSelected: cadence == option
            )
        }

        if isEditable {
            Button {
                withAnimation(.snappy) {
                    onSelect(option)
                }

                Task {
                    await hapticFeedback(.rigid)
                }
            } label: {
                tile
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(option.title))
        } else {
            tile
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(option.title))
        }
    }
}
