import SharedModels
import SwiftUI

struct JournalEntriesSheet: View {
  @ObservedObject var valuationStore: ValuationStore
  @Environment(\.dismiss) private var dismiss
  @State private var selectedEntry: DayValuation?

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
  }()

  private var journalEntries: [DayValuation] {
    valuationStore.valuations.values
      .filter { valuation in
        let trimmed = valuation.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !trimmed.isEmpty
      }
      .sorted { lhs, rhs in
        lhs.timestamp > rhs.timestamp
      }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {

          Text("All your journal notes in one place.")
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)

          CustomSeparator()
            .padding(.horizontal, -16)
            .padding(.top, 8)

          if journalEntries.isEmpty {
            Text("No journal entries yet.")
              .font(.system(size: 14, design: .monospaced))
              .foregroundColor(.textTertiary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
          } else {
            LazyVStack(spacing: 0) {
              ForEach(journalEntries, id: \.id) { entry in
                VStack(spacing: 0) {
                  Button(action: { selectedEntry = entry }) {
                    HStack(alignment: .top, spacing: 12) {
                      RoundedRectangle(cornerRadius: 3)
                        .fill(Color(entry.mood.color))
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)

                      VStack(alignment: .leading, spacing: 6) {
                        Text(Self.dateFormatter.string(from: entry.timestamp))
                          .font(.system(size: 12, design: .monospaced))
                          .foregroundStyle(.textTertiary)

                        if let note = entry.note {
                          Text(note)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3)
                        }
                      }

                      Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                  }
                  .buttonStyle(.plain)

                  CustomSeparator()
                    .padding(.horizontal, -16)
                }
                .listRowInsets(.init())
              }
            }
            .padding(.horizontal)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      }
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle("Journal")
      .navigationBarTitleDisplayMode(.large)
    }
    .sheet(item: $selectedEntry) { entry in
      JournalEntryDetailSheet(entry: entry, valuationStore: valuationStore)
    }
  }
}

#Preview {
  JournalEntriesSheet(valuationStore: .shared)
}
