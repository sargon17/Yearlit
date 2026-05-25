import SharedModels
import SwiftUI

struct HabitStacksHome: View {
    @ObservedObject var store: HabitStackStore
    @State private var isPresentingCreate = false
    @State private var editingStack: HabitStack?
    @State private var lastErrorMessage: String?

    var body: some View {
        VStack {
            List {
                if store.stacks.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No habit stacks yet").h4()
                            Text("Create your first stack to chain habits together.").body()
                        }

                        Button(action: addSampleStack) {
                            Text("Add Morning Routine Sample")
                                .buttonLabel()
                        }
                        .button()
                    }
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .overlay(
                        VStack {
                            CustomSeparator()
                            Spacer()
                            CustomSeparator()
                        }
                    )
                } else {
                    Section {
                        ForEach(store.stacks) { stack in
                            VStack {
                                Button {
                                    editingStack = stack
                                } label: {
                                    HabitStackRow(stack: stack)
                                }
                                .buttonStyle(.plain)
                                CustomSeparator()
                            }
                        }
                        .onDelete(perform: deleteStacks)
                        .onMove(perform: moveStacks)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.inset)
            .navigationTitle("Stacks")
        }
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
                title: String(localized: "Brew coffee"),
                detail: String(localized: "Fill the kettle and set out the mug."),
                order: 0,
                createdAt: now,
                updatedAt: now
            ),
            HabitStackStep(
                stackId: stackId,
                title: String(localized: "Read 5 pages"),
                detail: String(localized: "Sit on the sofa and open your current book."),
                order: 1,
                createdAt: now,
                updatedAt: now
            ),
            HabitStackStep(
                stackId: stackId,
                title: String(localized: "Plan day"),
                detail: String(localized: "Write top 3 priorities in the journal."),
                order: 2,
                createdAt: now,
                updatedAt: now
            ),
        ]

        do {
            let stack = try HabitStack(
                id: stackId,
                name: String(localized: "Morning Routine"),
                prompt: String(localized: "After I wake up"),
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
