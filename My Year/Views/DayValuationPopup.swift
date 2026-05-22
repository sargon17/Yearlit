import SharedModels
import SwiftUI

struct DayValuationPopup: View {
    @Environment(\.dismiss) private var dismiss
    let store = ValuationStore.shared
    let date: Date
    private let presentationDetents: Set<PresentationDetent>

    @State private var selectedMood: DayMood?
    @State private var noteText: String = ""
    @State private var showNoteEditor = false
    @State private var showNoteEditorContent = false
    @FocusState private var isNoteFocused: Bool

    private var bounceAnimation: Animation {
        .spring(response: 0.38, dampingFraction: 0.78, blendDuration: 0.12)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    init(date: Date, presentationDetents: Set<PresentationDetent> = [.height(420)]) {
        self.date = date
        self.presentationDetents = presentationDetents
    }

    private var existingValuation: DayValuation? {
        store.getValuation(for: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How was your day?")
                            .font(AppFont.pixelCircle(32))
                            .foregroundStyle(.textPrimary)

                        Text(formattedDate)
                            .font(AppFont.mono(16, weight: .regular))
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                CustomSeparator()
                    .padding(.horizontal, -24)

                VStack(spacing: 8) {
                    Spacer(minLength: 0)
                    HStack(spacing: 12) {
                        ForEach([DayMood.terrible, .bad, .neutral, .good, .excellent], id: \.self) { mood in
                            let isSelected = selectedMood == mood
                            Button(action: {
                                let shouldRevealEditor = !showNoteEditor
                                noteText = store.getValuation(for: date)?.note ?? ""
                                withAnimation(bounceAnimation) {
                                    selectedMood = mood
                                    showNoteEditor = true
                                }
                                if shouldRevealEditor {
                                    showNoteEditorContent = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        withAnimation(bounceAnimation) {
                                            showNoteEditorContent = true
                                        }
                                    }
                                } else {
                                    showNoteEditorContent = true
                                }
                                Task {
                                    await hapticFeedback(.rigid)
                                }
                            }) {
                                Text(mood.rawValue)
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(Color(mood.color))
                                            .opacity(0.2)
                                    )
                            }
                            .opacity(showNoteEditor && !isSelected ? 0.35 : 1)
                            .blur(radius: showNoteEditor && !isSelected ? 4 : 0)
                            .scaleEffect(showNoteEditor && !isSelected ? 0.92 : 1)
                        }
                    }
                    .offset(y: showNoteEditor ? -24 : 0)
                    .scaleEffect(showNoteEditor ? 0.60 : 1)

                    if showNoteEditor {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Journal")
                                    .font(AppFont.mono(12))
                                    .foregroundStyle(.textTertiary)
                                Spacer()
                            }

                            TextEditor(text: $noteText)
                                .focused($isNoteFocused)
                                .layoutPriority(1)
                                .frame(maxHeight: .infinity)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .inputStyle(radius: 6, color: .textPrimary)
                        }
                        .frame(maxHeight: .infinity)
                        .frame(maxHeight: showNoteEditorContent ? .infinity : 0)
                        .opacity(showNoteEditorContent ? 1 : 0)
                        .scaleEffect(x: 1, y: showNoteEditorContent ? 1 : 0.94, anchor: .top)
                        .blur(radius: showNoteEditorContent ? 0 : 6)
                        .clipped()
                    }

                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        Button(action: {
                            if showNoteEditor {
                                guard let selectedMood else { return }
                                store.setValuation(selectedMood, for: date, note: noteText)
                                Analytics.shared.track(
                                    .moodLogged,
                                    properties: [
                                        "has_note": .bool(!noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    ]
                                )
                                dismiss()
                            } else {
                                dismiss()
                            }
                            Task {
                                await hapticFeedback(.rigid)
                            }
                        }) {
                            HStack(spacing: 8) {
                                if showNoteEditor {
                                    Image(systemName: "checkmark")
                                    Text("Save")
                                } else {
                                    Text("Skip")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.bold)
                            .padding()
                        }
                        .sameLevelBorder()
                        .foregroundStyle(.textSecondary)
                    }
                    .padding(.all, 2)
                }
                .padding(.top, 8)
                .frame(maxHeight: .infinity)
            }

            Spacer(minLength: 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surfaceBackground(Color("surface-muted"))
        .presentationDetents(presentationDetents)
        .presentationBackground(Color("surface-muted"))
        .animation(bounceAnimation, value: showNoteEditor)
        .animation(bounceAnimation, value: showNoteEditorContent)
        .onAppear {
            guard let valuation = existingValuation else { return }
            selectedMood = valuation.mood
            noteText = valuation.note ?? ""
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showNoteEditor = true
                showNoteEditorContent = true
            }
        }
    }
}

#Preview {
    DayValuationPopup(date: Date())
}
