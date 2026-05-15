import SharedModels
import SwiftUI

struct EditableStepRow: View {
    @Binding var step: EditableStep
    let accentColor: Color
    let calendars: [CustomCalendar]
    let index: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("Step \(index + 1)")
                    .labelStyle(type: .secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button(
                        action: onMoveUp,
                        label: {
                            Image(systemName: "chevron.up")
                                .font(AppFont.mono(14, weight: .semibold))
                                .foregroundStyle(canMoveUp ? .textSecondary : .textTertiary)
                        }
                    )
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)

                    Button(
                        action: onMoveDown,
                        label: {
                            Image(systemName: "chevron.down")
                                .font(AppFont.mono(14, weight: .semibold))
                                .foregroundStyle(canMoveDown ? .textSecondary : .textTertiary)
                        }
                    )
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)

                    Button(
                        role: .destructive, action: onDelete,
                        label: {
                            Image(systemName: "trash")
                                .font(AppFont.mono(14, weight: .semibold))
                                .foregroundStyle(.moodTerrible)
                        }
                    )
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical)

            VStack(spacing: 6) {
                TextField(
                    "",
                    text: $step.title,
                    prompt: Text("Brew coffee").foregroundColor(.white.opacity(0.2))
                )
                .textInputAutocapitalization(.sentences)
                .inputStyle(color: colorScheme == .dark ? .textPrimary : .surfacePrimary)

                TextField(
                    "",
                    text: $step.detail,
                    prompt: Text("Optional detail").foregroundColor(.white.opacity(0.2)),
                    axis: .vertical
                )
                .lineLimit(3 ... 3)
                .inputStyle(size: .small, radius: 4, color: colorScheme == .dark ? .textSecondary : .surfaceMuted)
                .scrollDismissesKeyboard(.immediately)

                if calendars.isEmpty {
                    Label("Link calendars once you create them.", systemImage: "calendar.badge.plus")
                        .font(AppFont.mono(12))
                        .foregroundStyle(.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .sameLevelBorder()
                } else {
                    VStack {
                        HStack(spacing: 12) {
                            Text("Linked calendar")
                                .labelStyle(type: .secondary)
                            Spacer()
                            Picker(
                                "",
                                selection: Binding(
                                    get: { step.linkedCalendarId },
                                    set: { step.linkedCalendarId = $0 }
                                )
                            ) {
                                Text("None").tag(UUID?.none)
                                ForEach(calendars) { calendar in
                                    Text(calendar.name).tag(Optional(calendar.id))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(.textPrimary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .sameLevelBorder()
                    }
                    .padding(1)
                    .background(getVoidColor(colorScheme: colorScheme))
                    .cornerRadius(5)
                    .outerSameLevelShadow(radius: 5)
                }
            }
        }
        // .padding(4)
        // .sameLevelBorder(radius: 5)
    }
}
