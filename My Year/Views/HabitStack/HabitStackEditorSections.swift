import SharedModels
import SwiftUI

struct HabitStackNameSection: View {
    @Binding var name: String
    let accentColor: Color
    let focusBinding: FocusState<Bool>.Binding

    var body: some View {
        CustomSection(label: "Stack Name") {
            TextField(
                "",
                text: $name,
                prompt: Text("Morning Routine").foregroundColor(.white.opacity(0.2))
            )
            .textInputAutocapitalization(.words)
            .inputStyle(color: accentColor)
            .focused(focusBinding)
        }
    }
}

struct HabitStackPromptSection: View {
    @Binding var prompt: String
    let accentColor: Color

    var body: some View {
        CustomSection(label: "Prompt (optional)") {
            TextField(
                "",
                text: $prompt,
                prompt: Text("After I wake up").foregroundColor(.white.opacity(0.2))
            )
            .textInputAutocapitalization(.sentences)
            .lineLimit(1 ... 3)
            .inputStyle(color: accentColor)
        }
    }
}

struct HabitStackReminderSection: View {
    @Binding var scheduleEnabled: Bool
    @Binding var scheduleTime: Date
    let accentColor: Color

    var body: some View {
        CustomSection(label: "Schedule Reminder") {
            VStack(spacing: 2) {
                HStack {
                    Text("Set a reminder")
                        .labelStyle(type: .secondary)
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { scheduleEnabled },
                            set: { newValue in
                                withAnimation(.snappy) {
                                    scheduleEnabled = newValue
                                }
                            }
                        )
                    )
                }
                .tint(accentColor)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .sameLevelBorder()

                if scheduleEnabled {
                    HStack {
                        DatePicker(
                            "",
                            selection: $scheduleTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .tint(accentColor)
                        .inputStyle(radius: 4, color: .textPrimary)
                        .colorScheme(.dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.all, 2)
                    .sameLevelBorder()
                }
            }
            .padding(.all, 1)
            .sameLevelGroupBackground()
            .cornerRadius(5)
            .outerSameLevelShadow(radius: 5)
        }
    }
}

struct HabitStackStepsSection: View {
    @Binding var steps: [EditableStep]
    let calendars: [CustomCalendar]
    let accentColor: Color
    let addStep: () -> Void
    let moveStep: (EditableStep, Int) -> Void
    let removeStep: (EditableStep) -> Void

    var body: some View {
        CustomSection(label: "Steps") {
            VStack(spacing: 12) {
                CustomSeparator()

                if steps.isEmpty {
                    Text("Add at least one habit to the stack.")
                        .labelStyle(type: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                } else {
                    VStack(spacing: 20) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            EditableStepRow(
                                step: $steps[index],
                                accentColor: accentColor,
                                calendars: calendars,
                                index: index,
                                canMoveUp: index > 0,
                                canMoveDown: index < steps.count - 1,
                                onMoveUp: { moveStep(step, -1) },
                                onMoveDown: { moveStep(step, 1) },
                                onDelete: { removeStep(step) }
                            )

                            CustomSeparator()
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                Button(
                    action: addStep,
                    label: {
                        Label("Add Step", systemImage: "plus")
                            .buttonLabel()
                    }
                )
                .button()
            }
        }
    }
}
