import SharedModels
import SwiftUI

struct JournalEntryDetailSheet: View {
    let entry: DayValuation
    @ObservedObject var valuationStore: ValuationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var noteText: String
    @State private var hasChanges = false
    @FocusState private var isNoteFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    init(entry: DayValuation, valuationStore: ValuationStore) {
        self.entry = entry
        self.valuationStore = valuationStore
        _noteText = State(initialValue: entry.note ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Self.dateFormatter.string(from: entry.timestamp))
                            .font(AppFont.pixelCircle(28))
                            .foregroundStyle(.textPrimary)

                        HStack(spacing: 8) {
                            Text("Mood journal /")
                                .font(AppFont.mono(12))
                                .foregroundStyle(.textTertiary)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(entry.mood.color))
                                .frame(width: 10, height: 10)
                        }
                    }

                    Spacer(minLength: 0)
                }

                CustomSeparator()
                    .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $noteText)
                        .focused($isNoteFocused)
                        .frame(maxHeight: .infinity)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .inputStyle(radius: 6, color: .textPrimary)
                }
                .frame(maxHeight: .infinity)

                VStack(spacing: 2) {
                    Button(action: saveEntry) {
                        Text("Save")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.bold)
                            .padding()
                    }
                    .sameLevelBorder()
                    .foregroundStyle(.textSecondary)
                }
                .padding(.all, 2)
                .background(getVoidColor(colorScheme: colorScheme))
            }
            .padding()
            .padding(.top, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
        }
        .onChange(of: noteText) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            hasChanges = trimmed != (entry.note ?? "")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isNoteFocused = true
            }
        }
    }

    private func saveEntry() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        valuationStore.setValuation(entry.mood, for: entry.timestamp, note: trimmed)
        dismiss()
    }
}

#Preview {
    JournalEntryDetailSheet(entry: DayValuation(date: Date(), mood: .good, note: "Hello"), valuationStore: .shared)
}
