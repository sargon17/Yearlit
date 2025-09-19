import SharedModels
import SwiftUI

struct HabitStackEditorView: View {
  enum Mode: Equatable {
    case create
    case edit(HabitStack)
  }

  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var calendarStore = CustomCalendarStore.shared
  @ObservedObject var store: HabitStackStore

  @State private var stackId: UUID
  @State private var name: String
  @State private var prompt: String
  @State private var scheduleEnabled: Bool
  @State private var scheduleTime: Date
  @State private var steps: [EditableStep]
  @State private var errorMessage: String?
  @State private var isSaving = false
  @State private var editMode: EditMode = .inactive

  private let mode: Mode

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

    case let .edit(stack):
      _stackId = State(initialValue: stack.id)
      _name = State(initialValue: stack.name)
      _prompt = State(initialValue: stack.prompt ?? "")
      if let hour = stack.scheduledHour, let minute = stack.scheduledMinute,
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

  private var isEditing: Bool {
    if case .edit = mode { return true }
    return false
  }

  private var saveButtonLabel: String { isEditing ? "Save" : "Create" }

  private var canSave: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && steps.contains { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      && !isSaving
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Stack Details") {
          TextField("Name", text: $name)
            .textInputAutocapitalization(.words)

          TextField("Prompt (optional)", text: $prompt, axis: .vertical)
            .lineLimit(1...3)

          Toggle(isOn: $scheduleEnabled) {
            Label("Schedule reminder", systemImage: "alarm")
          }

          if scheduleEnabled {
            DatePicker(
              "Reminder time",
              selection: $scheduleTime,
              displayedComponents: .hourAndMinute
            )
          }
        }

        Section("Steps") {
          if steps.isEmpty {
            Text("Add at least one habit to the stack.")
              .foregroundStyle(.secondary)
          }

          ForEach(steps) { step in
            EditableStepRow(step: binding(for: step), calendars: calendarStore.calendars)
          }
          .onDelete { indexSet in
            steps.remove(atOffsets: indexSet)
          }
          .onMove { indices, newOffset in
            steps.move(fromOffsets: indices, toOffset: newOffset)
          }

          Button(action: addStep) {
            Label("Add Step", systemImage: "plus")
              .frame(maxWidth: .infinity)
          }
        }
      }
      .listStyle(.insetGrouped)
      .environment(\.editMode, $editMode)
      .navigationTitle(isEditing ? "Edit Stack" : "New Stack")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(saveButtonLabel) { save() }
            .disabled(!canSave)
        }
        ToolbarItem(placement: .navigationBarLeading) {
          if !steps.isEmpty {
            EditButton()
          }
        }
      }
      .alert(
        "Unable to save",
        isPresented: Binding(
          get: { errorMessage != nil },
          set: { newValue in if !newValue { errorMessage = nil } }
        ), actions: {}
      ) {
        if let message = errorMessage {
          Text(message)
        }
      }
    }
  }

  private func binding(for step: EditableStep) -> Binding<EditableStep> {
    guard let index = steps.firstIndex(of: step) else {
      fatalError("Step not found")
    }
    return $steps[index]
  }

  private func addStep() {
    let now = Date()
    let newStep = EditableStep(
      id: UUID(),
      title: "",
      detail: "",
      linkedCalendarId: nil,
      order: steps.count,
      createdAt: now,
      updatedAt: now
    )
    steps.append(newStep)
  }

  private func save() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      errorMessage = "Give the stack a name."
      return
    }

    let sanitizedSteps =
      steps
      .enumerated()
      .compactMap { index, editable -> HabitStackStep? in
        let trimmedTitle = editable.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }
        let trimmedDetail = editable.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return HabitStackStep(
          id: editable.id,
          stackId: stackId,
          title: trimmedTitle,
          detail: trimmedDetail.isEmpty ? nil : trimmedDetail,
          linkedCalendarId: editable.linkedCalendarId,
          order: index,
          createdAt: editable.createdAt,
          updatedAt: Date()
        )
      }

    guard !sanitizedSteps.isEmpty else {
      errorMessage = "Add at least one step before saving."
      return
    }

    let components = Calendar.current.dateComponents([.hour, .minute], from: scheduleTime)
    let hour = scheduleEnabled ? components.hour : nil
    let minute = scheduleEnabled ? components.minute : nil

    isSaving = true

    do {
      let existing: HabitStack? = {
        if case let .edit(stack) = mode { return stack }
        return nil
      }()

      let stack = try HabitStack(
        id: stackId,
        name: trimmedName,
        prompt: prompt.trimmedOrNil,
        scheduledHour: hour,
        scheduledMinute: minute,
        order: existing?.order ?? store.stacks.count,
        steps: sanitizedSteps,
        createdAt: existing?.createdAt ?? Date(),
        updatedAt: Date()
      )

      if isEditing {
        store.updateStack(stack)
      } else {
        store.addStack(stack)
      }
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }

    isSaving = false
  }

  private static func makeDate(hour: Int, minute: Int) -> Date? {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)
  }
}

struct EditableStep: Identifiable, Hashable {
  var id: UUID
  var title: String
  var detail: String
  var linkedCalendarId: UUID?
  var order: Int
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID,
    title: String,
    detail: String,
    linkedCalendarId: UUID?,
    order: Int,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.linkedCalendarId = linkedCalendarId
    self.order = order
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  init(step: HabitStackStep) {
    self.init(
      id: step.id,
      title: step.title,
      detail: step.detail ?? "",
      linkedCalendarId: step.linkedCalendarId,
      order: step.order,
      createdAt: step.createdAt,
      updatedAt: step.updatedAt
    )
  }
}
