import SharedModels
import SwiftUI

struct HabitStacksHome: View {
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
                description: Text("Create your first stack to chain habits together.")
              )

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
      .alert(
        "Oops",
        isPresented: Binding(
          get: { lastErrorMessage != nil },
          set: { newValue in if !newValue { lastErrorMessage = nil } }
        ), actions: {}
      ) {
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
