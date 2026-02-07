import SharedModels
import SwiftUI

struct HabitStackEditorView: View {
  enum Mode: Equatable {
    case create
    case edit(HabitStack)
  }

  @Environment(\.dismiss) var dismiss
  @ObservedObject private var calendarStore = CustomCalendarStore.shared
  @ObservedObject var store: HabitStackStore

  @State var stackId: UUID
  @State var name: String
  @State var prompt: String
  @State var scheduleEnabled: Bool
  @State var scheduleTime: Date
  @State var steps: [EditableStep]
  @State var errorMessage: String?
  @State var isSaving = false
  @FocusState var isNameFocused: Bool

  let mode: Mode

  init(mode: Mode, store: HabitStackStore) {
    self.mode = mode
    self.store = store

    switch mode {
    case .create:
      let newId = UUID()
      _stackId = State(initialValue: newId)
      _name = State(initialValue: "")
      _prompt = State(initialValue: "")
      _scheduleEnabled = State(initialValue: false)
      _scheduleTime = State(initialValue: Date())
      _steps = State(initialValue: [])

    case .edit(let stack):
      _stackId = State(initialValue: stack.id)
      _name = State(initialValue: stack.name)
      _prompt = State(initialValue: stack.prompt ?? "")
      if let hour = stack.scheduledHour,
        let minute = stack.scheduledMinute,
        let date = HabitStackEditorView.makeDate(hour: hour, minute: minute)
      {
        _scheduleEnabled = State(initialValue: true)
        _scheduleTime = State(initialValue: date)
      } else {
        _scheduleEnabled = State(initialValue: false)
        _scheduleTime = State(initialValue: Date())
      }
      _steps = State(initialValue: stack.stepsSorted.map { EditableStep(step: $0) })
    }
  }

  var isEditing: Bool {
    if case .edit = mode { return true }
    return false
  }

  private var accentColor: Color { Color("qs-emerald") }

  private var saveButtonLabel: String { isEditing ? "Save" : "Create" }

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && steps.contains { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      && !isSaving
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          HabitStackNameSection(
            name: $name,
            accentColor: accentColor,
            focusBinding: $isNameFocused
          )

          HabitStackPromptSection(
            prompt: $prompt,
            accentColor: accentColor
          )

          HabitStackReminderSection(
            scheduleEnabled: $scheduleEnabled,
            scheduleTime: $scheduleTime,
            accentColor: accentColor
          )

          HabitStackStepsSection(
            steps: $steps,
            calendars: calendarStore.calendars,
            accentColor: accentColor,
            addStep: addStep,
            moveStep: moveStep,
            removeStep: removeStep
          )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      }
      .scrollDismissesKeyboard(.immediately)
      .scrollIndicators(.hidden)
      .scrollClipDisabled(true)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle(isEditing ? "Edit Stack" : "New Stack")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(saveButtonLabel) { save() }
            .disabled(!canSave)
        }
      }
      .accentColor(accentColor)
      .alert(
        "Unable to save",
        isPresented: Binding(
          get: { errorMessage != nil },
          set: { newValue in if !newValue { errorMessage = nil } }
        ),
        actions: {},
        message: {
          if let message = errorMessage {
            Text(message)
          }
        }
      )
    }
  }
}
