import SharedModels
import SwiftUI
import SwiftfulRouting

struct StackSection: View {
  @StateObject private var store = HabitStackStore.shared

  var body: some View {
    RouterView { _ in
      HabitStacksHome(store: store)
    }
  }
}

private struct HabitStacksHome: View {
  @ObservedObject var store: HabitStackStore
  @State private var isPresentingCreate = false
  @State private var editingStack: HabitStack?
  @State private var lastErrorMessage: String?

  var body: some View {
    NavigationStack {
      List {
        if store.stacks.isEmpty {
          Section {
            VStack(spacing: 16) {
              ContentUnavailableView(
                "No habit stacks yet",
                systemImage: "rectangle.stack.badge.plus",
                description: Text("Create your first stack to chain habits together."))

              Button(action: addSampleStack) {
                Label("Add Morning Routine Sample", systemImage: "sun.and.horizon")
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 16)
          }
        } else {
          Section("Your Stacks") {
            ForEach(store.stacks) { stack in
              Button {
                editingStack = stack
              } label: {
                HabitStackRow(stack: stack)
              }
              .buttonStyle(.plain)
            }
            .onDelete(perform: deleteStacks)
            .onMove(perform: moveStacks)
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Habit Stacks")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if !store.stacks.isEmpty {
            EditButton()
          }
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            isPresentingCreate = true
          } label: {
            Label("New Stack", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $isPresentingCreate) {
        HabitStackEditorView(mode: .create, store: store)
          .presentationDetents([.medium, .large])
      }
      .sheet(item: $editingStack) { stack in
        HabitStackEditorView(mode: .edit(stack), store: store)
          .presentationDetents([.medium, .large])
      }
      .alert("Oops", isPresented: Binding(
        get: { lastErrorMessage != nil },
        set: { newValue in if !newValue { lastErrorMessage = nil } }
      ), actions: {}) {
        if let message = lastErrorMessage {
          Text(message)
        }
      }
    }
  }

  private func deleteStacks(at offsets: IndexSet) {
    let ids = offsets.map { store.stacks[$0].id }
    ids.forEach { store.deleteStack(id: $0) }
  }

  private func moveStacks(from offsets: IndexSet, to destination: Int) {
    store.moveStack(fromOffsets: offsets, toOffset: destination)
  }

  private func addSampleStack() {
    let stackId = UUID()
    let now = Date()
    let steps: [HabitStackStep] = [
      HabitStackStep(
        stackId: stackId,
        title: "Brew coffee",
        detail: "Fill the kettle and set out the mug.",
        order: 0,
        createdAt: now,
        updatedAt: now
      ),
      HabitStackStep(
        stackId: stackId,
        title: "Read 5 pages",
        detail: "Sit on the sofa and open your current book.",
        order: 1,
        createdAt: now,
        updatedAt: now
      ),
      HabitStackStep(
        stackId: stackId,
        title: "Plan day",
        detail: "Write top 3 priorities in the journal.",
        order: 2,
        createdAt: now,
        updatedAt: now
      )
    ]

    do {
      let stack = try HabitStack(
        id: stackId,
        name: "Morning Routine",
        prompt: "After I wake up",
        scheduledHour: 7,
        scheduledMinute: 0,
        order: store.stacks.count,
        steps: steps,
        createdAt: now,
        updatedAt: now
      )
      store.addStack(stack)
    } catch {
      lastErrorMessage = error.localizedDescription
    }
  }
}

private struct HabitStackRow: View {
  let stack: HabitStack

  private var scheduleLabel: String? {
    guard let hour = stack.scheduledHour, let minute = stack.scheduledMinute else { return nil }
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    if let date = Calendar.current.date(from: components) {
      return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
    return String(format: "%02d:%02d", hour, minute)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(stack.name)
          .font(.headline)
        Spacer()
        if let scheduleLabel {
          Label(scheduleLabel, systemImage: "alarm")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if let prompt = stack.prompt, !prompt.isEmpty {
        Text(prompt)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        Label("\(stack.steps.count) steps", systemImage: "list.number")
        if let first = stack.stepsSorted.first {
          Text("Starts with \(first.title)")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 8)
  }
}

private struct HabitStackEditorView: View {
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

    case .edit(let stack):
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
      .alert("Unable to save", isPresented: Binding(
        get: { errorMessage != nil },
        set: { newValue in if !newValue { errorMessage = nil } }
      ), actions: {}) {
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

    let sanitizedSteps = steps
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

private struct EditableStep: Identifiable, Hashable {
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

private struct EditableStepRow: View {
  @Binding var step: EditableStep
  let calendars: [CustomCalendar]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      TextField("Step title", text: $step.title)
        .textInputAutocapitalization(.sentences)

      TextField("Detail (optional)", text: $step.detail, axis: .vertical)
        .lineLimit(1...4)

      if calendars.isEmpty {
        Label("Link calendars to habits once you have them.", systemImage: "calendar")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        Picker("Linked calendar", selection: Binding(
          get: { step.linkedCalendarId },
          set: { step.linkedCalendarId = $0 }
        )) {
          Text("None").tag(UUID?.none)
          ForEach(calendars) { calendar in
            Text(calendar.name).tag(Optional(calendar.id))
          }
        }
        .pickerStyle(.menu)
      }
    }
    .padding(.vertical, 6)
  }
}

private extension String {
  var trimmedOrNil: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
